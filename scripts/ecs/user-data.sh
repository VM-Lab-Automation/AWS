#!/bin/bash
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_INSTANCE_ATTRIBUTES='${attributes}' >> /etc/ecs/ecs.config
docker run --name ecs-agent --detach=true --restart=on-failure:10 --volume=/var/run:/var/run --volume=/var/log/ecs/:/log --volume=/var/lib/ecs/data:/data --volume=/etc/ecs:/etc/ecs --net=host --env-file=/etc/ecs/ecs.config amazon/amazon-ecs-agent:latest