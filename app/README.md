# Maple Leaf Bank assistant (the workload)

The same small app used in [ai-quality-engineer](https://github.com/vnigam1985/ai-quality-engineer). There it is the system under test. Here it is the **workload your platform hosts**: a RAG chatbot plus an agent that can move money, which is exactly the kind of app a bank's AI platform has to make safe.

| Setting | Local (week 0) | Azure (week 5+) |
| --- | --- | --- |
| `LLM_MODE` | `llm` | `llm` |
| `OPENAI_BASE_URL` | `http://litellm:4000/v1` | `https://<apim>.azure-api.net/ai/openai/v1` |
| `OPENAI_API_KEY` | LiteLLM key | any non-empty value (APIM uses `api-key`) |
| `APIM_SUBSCRIPTION_KEY` | not set | APIM subscription key, from a Container Apps secret |
| `MODEL` | `gpt-4.1-mini` (alias served by Ollama) | `gpt-4.1-mini` (Foundry deployment name) |

The app never holds a model key. In Azure it only knows the gateway.
