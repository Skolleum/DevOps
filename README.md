# DevOps for Skolleum

This repository contains 
- Terraform code to integrate with Azure
- Ansible for automating provisioning and configuring the infrastructure
- Docker compose for container management.
- CircleCI for CICD pipelines.
    - Create up-to-date gundb image and push to github packages

Future plans:
- [ ] Store Skolleum containers (db, backend etc) on github packages (?).
- [ ] Integrate the deploy process to the pipelines.
- [ ] Add format checking to the pipeline.
