#!/bin/bash
echo ECS_CLUSTER=${cluster_name} >> /etc/ecs/ecs.config
echo ECS_INSTANCE_ATTRIBUTES='${attributes}' >> /etc/ecs/ecs.config