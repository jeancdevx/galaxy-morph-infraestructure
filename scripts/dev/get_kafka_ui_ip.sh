#!/bin/bash
# Obtiene la IP Pública de la tarea de ECS (Kafka UI) en el entorno dev

echo "Buscando la IP pública de Kafka UI en ECS..."

TASK_ARN=$(aws ecs list-tasks --profile jeancdev --region us-east-2 --cluster galaxy-morph-dev-kafka-ui --query "taskArns[0]" --output text)

if [ "$TASK_ARN" == "None" ] || [ -z "$TASK_ARN" ]; then
    echo "❌ No se encontró ninguna tarea ejecutándose en el clúster galaxy-morph-dev-kafka-ui."
    exit 1
fi

ENI_ID=$(aws ecs describe-tasks --profile jeancdev --region us-east-2 --cluster galaxy-morph-dev-kafka-ui --tasks "$TASK_ARN" --query "tasks[0].attachments[0].details[?name=='networkInterfaceId'].value" --output text)

PUBLIC_IP=$(aws ec2 describe-network-interfaces --profile jeancdev --region us-east-2 --network-interface-ids "$ENI_ID" --query "NetworkInterfaces[0].Association.PublicIp" --output text)

if [ "$PUBLIC_IP" == "None" ] || [ -z "$PUBLIC_IP" ]; then
    echo "❌ No se encontró una IP pública asignada a la tarea."
else
    echo "✅ Kafka UI está disponible en:"
    echo "👉 http://$PUBLIC_IP:8080"
fi
