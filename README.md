# 🌩️ Hosting Static Web Application in AWS (IaC)

Welcome to the official repository for Hosting Static Web Application in AWS (IaC) — a cloud infrastructure project designed to help migrate a static web application from an on-premises setup to a scalable, secure, and highly available AWS environment using Infrastructure as Code (IaC) with Terraform.

### 📘 Project Overview

The project was developed for Sum Cloud, a geography-based web game that was originally hosted on outdated on-premises hardware. Due to increased user traffic and performance issues, the application needed a more reliable and scalable solution.

>[!NOTE]
>
>Always use best security practice and follow company policy before deploying this infrastructure.

### 🛠️ Key Technologies & AWS Services Used

- Terraform: Provisioning and managing AWS resources

- Amazon S3: Hosting static content (HTML/JS)

- AWS CloudFront: Content Delivery Network (CDN) to reduce latency

- AWS Certificate Manager (ACM): SSL/TLS for HTTPS encryption

- AWS CodePipeline: CI/CD integration with GitHub for automated deployments

- AWS WAF: Web Application Firewall for enhanced security

### ✅ Project Highlights

- Fully modular and reusable Terraform codebase

- GitHub → CodePipeline → S3 automation flow

- HTTPS-enabled secure access via CloudFront

- Designed with scalability, availability, and cost-efficiency in mind

### 📦 Deliverables

This repository includes:

- Terraform scripts for provisioning all infrastructure

- Documentation for deployment and configuration

- Design blueprint of the architecture

### 📈 Outcome

By transitioning to AWS, Sum Cloud:

- Reduced latency across user locations

- Gained infrastructure scalability

- Achieved improved security with TLS and WAF

- Enabled continuous updates from GitHub via CodePipeline
