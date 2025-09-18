# scripts/create_agent.py

import os
from dotenv import load_dotenv, find_dotenv
from azure.identity import DefaultAzureCredential
from azure.ai.projects import AIProjectClient
from azure.ai.agents.models import CodeInterpreterTool

# Load environment variables from .env (searches up the tree)
load_dotenv(find_dotenv())

# Required / optional env vars
endpoint = os.getenv("PROJECT_ENDPOINT")  # e.g., https://<account>.services.ai.azure.com/api/projects/<project>
model = os.getenv("MODEL_DEPLOYMENT_NAME", "gpt-4o-mini")
agent_name = os.getenv("AGENT_NAME", "ci-agent")

if not endpoint:
    raise RuntimeError("Missing PROJECT_ENDPOINT in environment/.env")

# Authenticate using Azure credentials (works with az login, MSI, or SPN vars)
credential = DefaultAzureCredential()
client = AIProjectClient(endpoint=endpoint, credential=credential)

# Idempotent: create if missing; otherwise update
agents = list(client.agents.list())
agent = next((a for a in agents if a.name == agent_name), None)

if agent is None:
    agent = client.agents.create(
        name=agent_name,
        model=model,
        instructions="You are a helpful agent for CI smoke tests.",
        tools=[CodeInterpreterTool()],
    )
else:
    client.agents.update(agent_id=agent.id, instructions="(updated)")

print("Agent ready:", agent.id)
