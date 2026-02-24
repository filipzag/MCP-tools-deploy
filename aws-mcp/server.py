import asyncio
import json
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Request, HTTPException
from fastapi.responses import JSONResponse
from mcp import ClientSession
from mcp_proxy_for_aws.client import aws_iam_streamablehttp_client

# --- Configuration ---
AWS_MCP_URL = "https://aws-mcp.us-east-1.api.aws/mcp"
AWS_REGION = "us-east-1"
AWS_SERVICE = "aws-mcp" 

# Setup Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("mcp-bridge")

# Global Session Storage
aws_session: ClientSession | None = None

@asynccontextmanager
async def lifespan(app: FastAPI):
    global aws_session
    logger.info("Connecting to AWS MCP...")
    
    # FIXED: Context Manager Usage
    async with aws_iam_streamablehttp_client(
        AWS_MCP_URL, 
        aws_region=AWS_REGION, 
        aws_service=AWS_SERVICE,
        aws_profile="private"
    ) as (read_stream, write_stream, _):
        
        async with ClientSession(read_stream, write_stream) as session:
            aws_session = session
            await aws_session.initialize()
            
            logger.info("Connected to AWS MCP successfully.")
            yield
            logger.info("Closing AWS connection...")
            aws_session = None

app = FastAPI(lifespan=lifespan)

@app.post("/proxy")
async def handle_jsonrpc(request: Request):
    try:
        payload = await request.json()
    except json.JSONDecodeError:
        raise HTTPException(status_code=400, detail="Invalid JSON")

    method = payload.get("method")
    msg_id = payload.get("id")
    params = payload.get("params", {})

    if method == "initialize":
        return {
            "jsonrpc": "2.0",
            "id": msg_id,
            "result": {
                "protocolVersion": "2024-11-05",
                "capabilities": {
                    "tools": {"listChanged": False},
                    "resources": {"listChanged": False}
                },
                "serverInfo": {"name": "AWS-Bridge", "version": "1.0.0"}
            }
        }

    if method == "notifications/initialized":
        return JSONResponse(content={"jsonrpc": "2.0", "result": None})

    if method == "tools/list":
        if not aws_session:
            raise HTTPException(status_code=503, detail="AWS Session not ready")
        
        result = await aws_session.list_tools()
        tools_data = [
            {"name": t.name, "description": t.description, "inputSchema": t.inputSchema} 
            for t in result.tools
        ]
        return {"jsonrpc": "2.0", "id": msg_id, "result": {"tools": tools_data}}

    if method == "tools/call":
        tool_name = params.get("name")
        tool_args = params.get("arguments", {})
        
        try:
            result = await aws_session.call_tool(tool_name, arguments=tool_args)
            content = []
            if hasattr(result, "content"):
                for item in result.content:
                    if item.type == "text":
                        content.append({"type": "text", "text": item.text})
                    elif item.type == "image":
                        content.append({"type": "image", "data": item.data, "mimeType": item.mimeType})
            
            return {
                "jsonrpc": "2.0",
                "id": msg_id,
                "result": {"content": content, "isError": result.isError}
            }
        except Exception as e:
            logger.error(f"Tool execution failed: {e}")
            return {"jsonrpc": "2.0", "id": msg_id, "error": {"code": -32603, "message": str(e)}}

    if method == "ping":
        return {"jsonrpc": "2.0", "id": msg_id, "result": {}}

    return {"jsonrpc": "2.0", "id": msg_id, "error": {"code": -32601, "message": "Method not found"}}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=3001)