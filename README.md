# 🚀 BaatApp – Production-Grade AWS Infrastructure (Terraform)

This repository contains a **production-style AWS infrastructure** built using Terraform for a scalable backend application (chat / SaaS / fintech-style architecture).

The infrastructure follows real industry DevOps practices including:

* Multi-AZ networking
* Application Load Balancer
* Auto Scaling EC2 backend
* Private PostgreSQL RDS
* Private Redis ElastiCache
* Secure VPC design

---

# 🏗️ Architecture Overview

Users → Application Load Balancer → Auto Scaling EC2
↓
PostgreSQL (RDS)
Redis (ElastiCache)

### Key Principles Used

✅ Multi-Availability Zone deployment
✅ Public + Private subnet separation
✅ Backend instances behind Load Balancer
✅ Database and Redis kept private
✅ Infrastructure fully automated via Terraform

---

# 📦 Infrastructure Components

## 🌐 Networking

* Custom VPC
* Public subnets (for ALB + EC2)
* Private subnets (for RDS + Redis)
* Internet Gateway
* Route tables

---

## ⚖️ Load Balancer

* AWS Application Load Balancer
* Routes external traffic to backend instances
* Health checks enabled

---

## 🖥️ Compute Layer

* EC2 instances managed by **Auto Scaling Group**
* Launch Template with automatic startup script
* Backend runs on port **8000**

---

## 🗄️ Database

* PostgreSQL RDS
* Hosted inside private subnet
* Accessible only from backend security group

---

## ⚡ Cache Layer

* Redis (AWS ElastiCache)
* Used for:

  * Session caching
  * Online user tracking
  * Fast message handling

---

# 🚀 Deployment Instructions

## 1️⃣ Clone repository

```
git clone https://github.com/YOUR_USERNAME/Baatapp-infra.git
cd Baatapp-infra
```

---

## 2️⃣ Initialize Terraform

```
terraform init
```

---

## 3️⃣ Review plan

```
terraform plan
```

---

## 4️⃣ Apply infrastructure

```
terraform apply
```

---

# 🔐 Environment Notes

* Backend application must run on:

```
PORT=8000
HOST=0.0.0.0
```

* Infrastructure expects the backend service to respond on `/` for health checks.

---

# 🧪 Example Output Endpoints

After deployment Terraform outputs:

* Load Balancer DNS
* RDS endpoint
* Redis endpoint

---

# 🧠 Skills Demonstrated

This project demonstrates hands-on experience with:

* Terraform Infrastructure as Code
* AWS Networking (VPC / Subnets / Routing)
* Load Balancer configuration
* Auto Scaling architecture
* Managed Database deployment
* Redis caching infrastructure
* Secure production design patterns

---

# 🎯 Use Case

Designed as a backend infrastructure for:

* Chat applications
* SaaS platforms
* Fintech systems
* Real-time APIs

---

# 👨‍💻 Author

Built as a hands-on DevOps learning project focused on **real production architecture instead of demo-level setups**.

---

# ⭐ Future Improvements (Planned)

* HTTPS with ACM + Domain
* CI/CD pipeline (GitHub Actions)
* Dockerized backend deployment
* Remote Terraform state (S3 + DynamoDB locking)
* Monitoring with CloudWatch
