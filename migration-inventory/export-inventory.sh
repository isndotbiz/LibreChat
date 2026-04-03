#!/usr/bin/env bash
set -euo pipefail

HOST="${1:-46.224.100.66}"
REMOTE_DIR="${2:-/root/Workspace/librechat-hydra}"
OUT_DIR="${3:-migration-inventory}"
TS="$(date +%Y-%m-%d-%H%M%S)"

mkdir -p "$OUT_DIR"

ssh root@"$HOST" "docker exec librechat-hydra-mongodb-1 mongosh --quiet --eval '
const dbx=db.getSiblingDB(\"LibreChat\");
function trunc(s,n){ if(!s) return \"\"; s=String(s); return s.length>n ? s.slice(0,n) : s; }
const out={};
out.generatedAt=new Date().toISOString();
out.counts={};
for (const c of dbx.getCollectionNames()){ out.counts[c]=dbx.getCollection(c).countDocuments({}); }
out.dbStats=dbx.stats();
out.recentConversations=dbx.conversations.find({}, {title:1,updatedAt:1,createdAt:1,endpoint:1,model:1,isStarred:1,tags:1}).sort({updatedAt:-1, createdAt:-1}).limit(20).toArray().map(d=>({id:String(d._id), title:d.title||\"(untitled)\", updatedAt:d.updatedAt||d.createdAt||null, endpoint:d.endpoint||null, model:d.model||null, isStarred:!!d.isStarred, tags:d.tags||[]}));
out.presets=dbx.presets.find({}, {name:1,title:1,model:1,endpoint:1,temperature:1,prompt:1,systemPrompt:1,createdAt:1,updatedAt:1}).sort({updatedAt:-1, createdAt:-1}).toArray().map(p=>({id:String(p._id), name:p.name||p.title||\"(unnamed)\", endpoint:p.endpoint||null, model:p.model||null, temperature:p.temperature??null, systemPrompt100:trunc(p.systemPrompt||p.prompt,100), updatedAt:p.updatedAt||p.createdAt||null}));
out.prompts=dbx.prompts.find({}, {title:1,name:1,category:1,prompt:1,text:1,content:1,updatedAt:1,createdAt:1}).sort({updatedAt:-1,createdAt:-1}).toArray().map(p=>({id:String(p._id), title:p.title||p.name||\"(untitled)\", category:p.category||null, first50:trunc(p.prompt||p.text||p.content,50), updatedAt:p.updatedAt||p.createdAt||null}));
out.assistants=dbx.assistants.find({}, {name:1,title:1,description:1,tools:1,model:1,endpoint:1,updatedAt:1,createdAt:1}).toArray();
out.agents=dbx.agents.find({}, {name:1,title:1,description:1,tools:1,model:1,endpoint:1,updatedAt:1,createdAt:1}).toArray();
out.files=dbx.files.find({}, {filename:1,filepath:1,bytes:1,size:1,type:1,mimetype:1,source:1,conversationId:1,messageId:1,createdAt:1,updatedAt:1}).sort({updatedAt:-1,createdAt:-1}).limit(500).toArray();
out.users=dbx.users.find({}, {email:1,username:1,name:1,provider:1,createdAt:1}).toArray();
out.mcpservers=dbx.mcpservers.find({}, {name:1,label:1,type:1,url:1,serverUrl:1,enabled:1,updatedAt:1,createdAt:1}).toArray();
print(JSON.stringify(out));
'" > "$OUT_DIR/inventory-$TS.raw.json"

jq . "$OUT_DIR/inventory-$TS.raw.json" > "$OUT_DIR/inventory-$TS.json"
rm "$OUT_DIR/inventory-$TS.raw.json"

ssh root@"$HOST" "cd '$REMOTE_DIR' && sed -E 's/(API_KEY|TOKEN|SECRET|PASSWORD|KEY|IV|DSN)=.*/\\1=<redacted>/' .env" > "$OUT_DIR/env-redacted-$TS.txt"
ssh root@"$HOST" "cd '$REMOTE_DIR' && cat librechat.yaml" > "$OUT_DIR/librechat-$TS.yaml"

cp "$OUT_DIR/inventory-$TS.json" "$OUT_DIR/inventory-latest.json"

echo "exported: $OUT_DIR/inventory-$TS.json"
echo "exported: $OUT_DIR/env-redacted-$TS.txt"
echo "exported: $OUT_DIR/librechat-$TS.yaml"
