# Tutorial: Deploying Ghost Blog to Scaleway Serverless Containers

## 📚 What You'll Learn

In this tutorial, you'll learn how to deploy a production-ready Ghost blog using modern serverless architecture. By the end, you'll understand:

- **Serverless Architecture**: Why and how stateless containers differ from traditional servers
- **Infrastructure as Code**: Using Terraform to automate cloud resource provisioning
- **Container Deployment**: Building and deploying Docker images to a container registry
- **Cloud Storage**: Configuring S3-compatible object storage for media files
- **Database Management**: Setting up and connecting to managed MySQL databases
- **DNS & SSL**: Configuring custom domains with automatic HTTPS certificates

## 🎯 What We're Building

You'll deploy a fully-functional Ghost blogging platform that:

- Scales automatically based on traffic (1-5 instances)
- Stores media files in cloud object storage (S3)
- Uses a managed MySQL database for reliability
- Runs on your custom domain with automatic SSL certificates
- Costs approximately €35-50/month for low-traffic blogs

## 📋 Tutorial Difficulty & Time

- **Difficulty**: Intermediate
- **Time Required**:
  - Automated deployment (Terraform): ~30 minutes
  - Manual deployment: ~60 minutes
- **Prerequisites**: Basic command-line experience, basic Docker knowledge helpful

## 🧰 Prerequisites

Before starting, ensure you have:

1. **Scaleway Account** with payment method configured
   - [Sign up here](https://console.scaleway.com) if you don't have one
2. **Docker** installed locally
   - [Install Docker](https://docs.docker.com/get-docker/)
3. **Terraform >= 0.13** installed
   - [Install Terraform](https://developer.hashicorp.com/terraform/downloads)
4. **Scaleway API Keys**: Access Key ID and Secret Key
   - [Generate here](https://console.scaleway.com/project/credentials)
   - **Important**: For initial deployment, use an API Key with **Administrator** privileges
   - Terraform will create a dedicated IAM Application with exact required permissions for future runs
5. **Domain Name**: Access to DNS settings for your domain
   - Any domain registrar (GoDaddy, Namecheap, Cloudflare, etc.)

## 🏗️ Understanding Serverless Architecture

**What makes this deployment different?**

Traditional Ghost deployments run on a VPS (Virtual Private Server) where everything—database, files, and application—lives on one persistent server. Serverless containers are **stateless**, meaning:

- **No Persistent Storage**: Containers can be destroyed and recreated at any time
- **Auto-Scaling**: Automatically creates more instances during traffic spikes
- **Pay-Per-Use**: You only pay for actual usage, not idle server time

**This means we externalize everything that needs to persist:**

1. **Database**: Using Scaleway Managed Database (MySQL)
   - Your blog posts, users, and settings
2. **Content Storage**: Using Scaleway Object Storage (S3)
   - Images, themes, and uploaded files
3. **Configuration**: Stored as environment variables
   - Database credentials, S3 keys, domain settings

## 🚀 Choose Your Deployment Path

## Complete Step-by-Step Deployment Guide

### Prerequisites

Before starting, ensure you have:

1. **Scaleway Account** with payment method configured
2. **Docker** installed locally
3. **Terraform >= 0.13** installed (for automated deployment)
4. **Scaleway API Keys**: Access Key ID and Secret Key ([generate here](https://console.scaleway.com/project/credentials))
   - **Important**: For the **initial deployment**, you must use an API Key with **Administrator** privileges (e.g., your personal account key).
   - Terraform will create a dedicated IAM Application with the exact required permissions for future runs.
5. **Domain Name**: Access to DNS settings for your domain

### Option A: Automated Deployment with Terraform (⭐ Recommended)

**⏱️ Time**: ~30 minutes | **Difficulty**: Intermediate | **Best for**: Production deployments, repeatable infrastructure

**Why Terraform?**

- Automates all resource creation
- Ensures consistent, reproducible deployments
- Easy to update and version control your infrastructure
- Destroys all resources cleanly when needed

#### **Step 1: Setup Scaleway Credentials** ⏱️ 5 minutes

**What are API keys?**
API keys allow Terraform to authenticate with Scaleway and create resources on your behalf. Think of them as a username/password for automated tools.

1. **Get your API keys**:
   - Go to [Scaleway Console > Project Settings > Credentials](https://console.scaleway.com/project/credentials)
   - Click **Generate new API key**
   - **Save both** the Access Key ID and Secret Key (you won't see the secret again!)

2. **Store credentials securely**:

   Create a `.credentials` file in your home directory (outside this repo):

   ```bash
   # Create credentials file
   nano .scaleway_credentials
   ```

   Add your keys:

   ```bash
   export SCW_ACCESS_KEY="SCWxxxxxxxxxxxxxxxxx"
   export SCW_SECRET_KEY="xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
   export TF_VAR_scw_secret_key="$SCW_SECRET_KEY"
   ```

   Make it secure:

   ```bash
   chmod 600 .scaleway_credentials
   ```

3. **Load credentials** (for each terminal session):

   ```bash
   source .scaleway_credentials
   ```

   Or add to your `~/.bashrc` or `~/.zshrc` for automatic loading:

   ```bash
   echo "source .scaleway_credentials" >> ~/.bashrc
   ```

4. **Verify credentials are set**:

   ```bash
   echo $SCW_ACCESS_KEY  # Should show your access key
   ```

**⚠️ Never commit credentials to git** - they're in [`.gitignore`](../.gitignore:6) to prevent accidents.

#### **Step 2: Configure Your Deployment** ⏱️ 3 minutes

**What is `terraform.tfvars`?**
This file contains your deployment's specific settings (project ID, region, domain name). Terraform reads this file to customize the infrastructure for your needs.

```bash
cd terraform
cp terraform.tfvars.example terraform.tfvars
nano terraform.tfvars
```

Edit the values:

```hcl
project_id    = "your-project-id"                        # Find at: https://console.scaleway.com/project/settings
region        = "fr-par"                                 # Choose: fr-par, nl-ams, pl-waw
zone          = "fr-par-1"                               # Match your region
app_name      = "ghost-blog"                             # Your app name (used for resource naming)
custom_domain = "blog.example.com"                       # Your domain (or leave empty for default URL)
```

#### **Step 3: Initialize and Deploy Infrastructure** ⏱️ 10-15 minutes

**What happens during deployment?**
Terraform will create all necessary cloud resources automatically. This is called "Infrastructure as Code" (IaC).

```bash
cd terraform

# Initialize Terraform (first time or after provider updates)
terraform init

# Optional: Upgrade to latest provider versions
terraform init -upgrade

# Review what will be created/changed
terraform plan

# Apply the infrastructure changes
terraform apply   # Type 'yes' to confirm
```

**Updating Existing Infrastructure**:

If you've already deployed and need to update:

```bash
cd terraform
terraform plan    # Review changes
terraform apply   # Apply updates
```

**📦 What Terraform Creates**:

Understanding what gets created helps you troubleshoot and manage your deployment:

1. **Container Registry Namespace** - For storing Docker images (e.g., `ghost-blog-registry`)
2. **Docker Image Build & Push** - Automated (requires Docker running locally)
3. **MySQL 8 Database** (Managed)
   - Auto-generated secure passwords
   - SSL/TLS enforced
   - Automatic backups enabled
4. **S3 Object Storage Bucket**
   - Public bucket for media files
   - IAM application with full ObjectStorage permissions
   - **Bucket Policy** - Grants Ghost IAM app access to bucket (required for uploads)
   - CORS configured for web access
   - ACL set to public-read
5. **Serverless Container Namespace** - For organizing and running containers (e.g., `funcscwghostblognsjqzbkh9w`)
6. **Serverless Container** - Ghost application
   - All environment variables configured automatically
   - Secrets stored in Scaleway Secret Manager
   - Auto-scaling (1-5 instances)
   - 1 vCPU, 1GB RAM per instance
7. **Local `.env` file** - Auto-generated for docker-compose development

**💡 Understanding Container vs. Container Registry**:

You will see **two namespaces** in the Scaleway Console under "Container Registry":

- **Container Registry Namespace** ([`scaleway_registry_namespace`](terraform/main.tf:26)) - Stores your Docker images (shows storage usage in MB/GB)
- **Serverless Container Namespace** ([`scaleway_container_namespace`](terraform/main.tf:203)) - Runtime environment where your Ghost application runs (shows 0 B storage - this is correct)

These are **different resource types** that serve different purposes. Both are required for the deployment:

- The Container Registry stores your built Docker images
- The Serverless Container Namespace is where your Ghost app actually runs

Scaleway's UI groups both under "Container Registry" → "Namespaces", which can be confusing, but they're fundamentally different and both necessary.

#### **Step 4: Retrieve Deployment Information** ⏱️ 1 minute

After deployment succeeds, Terraform provides important URLs and configuration values:

```bash
terraform output
```

Note the following outputs:

- `container_url`: Your container's endpoint (e.g., `ghost-blog-xxxxx.functions.fnc.fr-par.scw.cloud`)
- `database_host`: MySQL host
- `bucket_name`: S3 bucket name
- `dns_configuration`: DNS settings needed

#### **Step 5: Configure DNS** ⏱️ 2 minutes (+ 5-15 min propagation)

**What is DNS?**
DNS (Domain Name System) translates human-readable domain names (blog.example.com) to server addresses. We need to point your domain to your Scaleway container.

**Steps:**
In your DNS provider (where you registered `example.com`):

1. Create a **CNAME record**:
   - **Name**: `blog`
   - **Value**: The `container_url` from Step 4
   - **TTL**: `3600`

2. Wait 5-15 minutes for DNS propagation

#### **Step 6: Add Custom Domain in Scaleway** ⏱️ 2 minutes (+ 5-15 min SSL provisioning)

**What is this step doing?**
This tells Scaleway to accept traffic from your custom domain and automatically provision a free SSL certificate (HTTPS) using Let's Encrypt.

1. Go to [Scaleway Console > Serverless > Containers](https://console.scaleway.com/serverless/containers)
2. Select your Ghost blog container
3. Click **Endpoints** tab → **Add custom domain**
4. Enter `blog.example.com`
5. Wait for SSL certificate provisioning (~5-15 minutes)

#### **Step 7: Complete Ghost Setup** ⏱️ 5 minutes

**Final step!** Now configure Ghost itself:

1. Visit `https://blog.example.com/ghost`
2. Create your admin account
3. Configure your blog settings
4. Start publishing! 🚀

#### **✅ Verification**

Test that everything is working correctly:

```bash
# Check DNS
nslookup blog.example.com

# Test endpoint
curl -I https://blog.example.com
```

---

### Option B: Manual Deployment

**⏱️ Time**: ~60 minutes | **Difficulty**: Advanced | **Best for**: Learning internals, debugging, custom configurations

**Why manual deployment?**
This approach teaches you exactly what Terraform automates. You'll gain deeper understanding of each component, which helps with troubleshooting and customization.

**What you'll do manually:**

1. Create a MySQL database through Scaleway console
2. Set up an S3 bucket for media storage
3. Build and push a Docker image
4. Configure a serverless container
5. Set up DNS and custom domain

#### **Step 1: Create MySQL Database** ⏱️ 10 minutes

**Why MySQL?**
Ghost requires a database to store your blog posts, users, settings, and metadata. We're using a managed database so Scaleway handles backups, updates, and maintenance.

1. Go to [Scaleway Console > Managed Databases](https://console.scaleway.com/rdb/instances)
2. Click **Create Database Instance**
3. Configure:
   - **Engine**: MySQL 8
   - **Node Type**: `db-play2-pico` (production) or `db-play2-pico` (dev/testing)
   - **Region**: `fr-par` (same as container)
   - **Database Name**: `ghost`
   - **Username**: `ghost`
   - **Settings**: Enable "require_secure_transport" for SSL/TLS
4. **Note down**: Host, Port (usually 3306), Username, Password

#### **Step 2: Create S3 Bucket for Media Storage** ⏱️ 10 minutes

**Why S3 storage?**
Serverless containers don't have persistent file storage. Any uploaded images or files would disappear when containers restart. S3 provides permanent, scalable storage for media files.

1. Go to [Scaleway Console > Object Storage](https://console.scaleway.com/object-storage/buckets)
2. Click **Create a Bucket**
3. Configure:
   - **Name**: `ghost-blog-content-<unique-id>` (must be globally unique)
   - **Region**: `fr-par` (same as container)
   - **Visibility**: Public (for serving images)
4. Set **CORS Policy**:
   - Go to bucket → **Bucket Settings** → **CORS**
   - Allow `GET`, `HEAD` methods from all origins (`*`)
5. **Create API Keys**:
   - Go to [Project Settings > API Keys](https://console.scaleway.com/project/credentials)
   - Generate a new key pair (Access Key ID + Secret Key)
   - Grant permission to the S3 bucket
6. **Note down**: Bucket name, Region, Access Key ID, Secret Key

#### **Step 3: Build and Push Docker Image** ⏱️ 15 minutes

**What is this doing?**
We're packaging Ghost with the S3 storage adapter into a Docker container image, then uploading it to Scaleway's container registry where it can be deployed.

1. **Create Container Registry Namespace**:
   - Go to [Scaleway Console > Container Registry](https://console.scaleway.com/registry/namespaces)
   - Create namespace (e.g., `ghost-blog`)

2. **Login to Registry**:

   ```bash
   echo "$SCW_SECRET_KEY" | docker login rg.fr-par.scw.cloud/ghost-blog -u nologin --password-stdin
   ```

3. **Build Image** (from `serverless-deployment/` directory):

   ```bash
   docker build --platform linux/amd64 -t rg.fr-par.scw.cloud/ghost-blog/ghost-s3:latest .
   ```

   > **Note**: `--platform linux/amd64` is required on Apple Silicon (M1/M2/M3) Macs

4. **Push Image**:

   ```bash
   docker push rg.fr-par.scw.cloud/ghost-blog/ghost-s3:latest
   ```

#### **Step 4: Deploy Serverless Container** ⏱️ 15 minutes

**What is a serverless container?**
Unlike Docker containers you run locally, serverless containers are managed by Scaleway. They automatically scale, restart on failure, and you only pay for actual usage.

1. Go to [Scaleway Console > Serverless > Containers](https://console.scaleway.com/serverless/containers)
2. Click **Deploy Container**
3. **Configuration**:
   - **Namespace**: Create or select (e.g., `ghost-blog-ns`)
   - **Name**: `ghost-blog`
   - **Container Image**: `ghost-s3:latest` from your registry
   - **Port**: `2368`
   - **Resources**:
     - CPU: 1 vCPU (1000m)
     - Memory: 1024 MB (Ghost requires ≥1GB)
   - **Scaling**:
     - Min: `1` (avoid cold starts)
     - Max: `5` (handle traffic spikes)

4. **Environment Variables** (⚠️ Critical):

   Set these in the container configuration (use **Secret** type for sensitive values):

   ```bash
   # General
   url=https://blog.example.com
   NODE_ENV=production
   
   # Database
   database__client=mysql
   database__connection__host=<YOUR_DB_HOST>
   database__connection__port=3306
   database__connection__user=ghost
   database__connection__password=<YOUR_DB_PASSWORD>    # Secret
   database__connection__database=ghost
   
   # S3 Storage
   storage__active=s3
   storage__s3__accessKeyId=<YOUR_SCW_ACCESS_KEY>      # Secret
   storage__s3__secretAccessKey=<YOUR_SCW_SECRET_KEY>  # Secret
   storage__s3__region=fr-par
   storage__s3__bucket=<YOUR_BUCKET_NAME>
   storage__s3__endpoint=https://s3.fr-par.scw.cloud
   storage__s3__forcePathStyle=true
   ```

5. Click **Deploy Container**

#### **Step 5: Configure Custom Domain & DNS** ⏱️ 10 minutes (+ propagation time)

**Connecting your domain:**
Now we'll make your blog accessible at your custom domain instead of the default Scaleway URL.

1. **Get Container URL**:
   - In Scaleway Console, go to your container → **Endpoints** tab
   - Copy the default URL (e.g., `ghost-blog-xxxxx.functions.fnc.fr-par.scw.cloud`)

2. **Add DNS CNAME Record** (in your DNS provider):

   ```
   Type: CNAME
   Name: blog
   Value: ghost-blog-xxxxx.functions.fnc.fr-par.scw.cloud
   TTL: 3600
   ```

3. **Add Custom Domain in Scaleway**:
   - In container **Endpoints** tab → **Add custom domain**
   - Enter: `blog.example.com`
   - Follow validation wizard

4. **Wait for SSL Certificate** (~5-15 minutes)

5. **Verify**:

   ```bash
   nslookup blog.example.com
   curl -I https://blog.example.com
   ```

#### **Step 6: Initialize Ghost** ⏱️ 5 minutes

**🎉 Final step!** Set up your Ghost admin account:

1. Visit `https://blog.example.com/ghost`
2. Create admin account
3. Configure blog settings
4. Start publishing! 🚀

---

## DNS Configuration Reference {#dns-configuration}

### Important Notes

- **Use CNAME, not A records**: Serverless containers don't have static IPs
- **DNS Propagation**: Can take 5 minutes to 48 hours (usually 15 minutes)
- **SSL Certificate**: Auto-provisioned by Scaleway via Let's Encrypt

### Example DNS Configuration

```
Type    Name    Value                                                TTL
CNAME   blog    ghost-blog-xxxxx.functions.fnc.fr-par.scw.cloud      3600
```

### Troubleshooting DNS

- **CNAME shows wrong value**: Some DNS providers auto-append domain; use just `blog` instead of `blog.example.com`
- **Custom domain not working**: Check DNS propagation with `nslookup` or `dig`
- **SSL errors**: Wait 15 minutes after DNS propagates for certificate provisioning

### S3 Storage and Image Uploads

**ImageUpload Fails with "Access Denied"**:

If you encounter `AccessDenied: Access Denied` errors when uploading images to Ghost, the most common cause is a **missing bucket policy**. Troubleshoot in this order:

**1. Verify Bucket Policy is Created**

The Terraform configuration automatically creates a bucket policy with `scaleway_object_bucket_policy.ghost_access`.

To verify it exists:

- Go to [Scaleway Console > Object Storage > Your Bucket > Bucket Policy tab](https://console.scaleway.com/object-storage/buckets)
- You should see a policy document with two statements: `GhostS3FullAccess` and `PublicRead`

If missing, apply Terraform:

```bash
cd terraform
terraform apply
```

The policy grants the Ghost IAM application full S3 access using Scaleway's formula:

```json
"Principal": { "SCW": "application_id:{ghost_application_id}" }
"Action": ["s3:*"]
```

**2. Verify Docker S3 Adapter Installation**

The Docker image must install the S3 adapter directly into Ghost's native location:

```dockerfile
RUN npm install ghost-storage-adapter-s3 \
    && mkdir -p ./content.orig/adapters/storage \
    && cp -vr ./node_modules/ghost-storage-adapter-s3 ./content.orig/adapters/storage/s3
```

Rebuild if Dockerfile was modified:

```bash
cd serverless-deployment
docker build --platform linux/amd64 -t rg.fr-par.scw.cloud/<namespace>/ghost-s3:latest .
docker push rg.fr-par.scw.cloud/<namespace>/ghost-s3:latest
```

**3. Verify S3 Environment Variables**

In [Scaleway Console > Serverless > Containers > Your Container > Environment variables](https://console.scaleway.com/serverless/containers):

✅ Set as **Secret** type (not regular):

- `storage__s3__accessKeyId`
- `storage__s3__secretAccessKey`

✅ Set as regular variables:

- `storage__s3__bucket` - Exact bucket name
- `storage__s3__region` - Same as bucket region (e.g., `fr-par`)
- `storage__s3__endpoint` - Format: `https://s3.{region}.scw.cloud`

**4. Verify IAM Application & API Key**

- Go to [Scaleway Console > IAM > API Keys](https://console.scaleway.com/iam/api-keys)
- Find your Ghost S3 application's API key
- Status must be **Active** (not expired)
- Associated policy must grant `ObjectStorageFullAccess`

**5. Verify Bucket Configuration**

- **ACL Setting**: Go to Bucket Settings → ACL → Should be `public-read`
- **CORS Setting**: Go to Bucket Settings → CORS → Should allow `PUT, POST, DELETE` methods

**6. Check Container Logs for Clues**

Go to [Scaleway Console > Serverless > Containers > Logs tab](https://console.scaleway.com/serverless/containers):

- `AccessDenied` → Check bucket policy first
- "Cannot locate credentials" → Check S3 environment variables are set as Secrets
- `NoSuchBucket` → Verify bucket name matches environment variable

**7. Redeploy After Making Changes**

```bash
# Full redeploy of Docker + Terraform
cd serverless-deployment
docker build --platform linux/amd64 -t rg.fr-par.scw.cloud/<namespace>/ghost-s3:latest .
docker push rg.fr-par.scw.cloud/<namespace>/ghost-s3:latest

cd ../terraform
terraform apply  # Applies bucket policy + container update
```

Test image upload in Ghost admin panel after deployment completes.

## Troubleshooting

### Deployment Issues

- **502 Bad Gateway**:
  - Check if the container is listening on port 2368
  - Review logs in the "Logging" tab of Scaleway Console
  - Verify memory isn't exhausted (increase to 1GB if needed)

- **Database Connection Error**:
  - Verify DB credentials in environment variables
  - Ensure Database and Container are in the same Private Network
  - Ensure database is in the same region as container
  - Verify SSL/TLS settings if enabled

- **Image Upload Fails** ("Access Denied" errors):
  - **Critical**: Verify bucket policy is configured (Terraform creates this automatically with `scaleway_object_bucket_policy.ghost_access`)
  - Verify the Docker image includes the S3 adapter installed in `./content.orig/adapters/storage/s3`
  - Check S3 credentials (access key and secret key in container environment)
  - Verify IAM policy grants `ObjectStorageFullAccess` at project level
  - Ensure bucket is in the same region as container
  - Check bucket ACL is set to `public-read`
  - Check CORS settings allow PUT, POST, DELETE methods
  - Rebuild and redeploy Docker image if Dockerfile was modified: `docker build ... && docker push ...`
  - Redeploy Terraform to apply bucket policy: `cd terraform && terraform apply`

### DNS Issues

- **Custom Domain Not Working**:
  - Wait for DNS propagation (5 min - 48 hours, usually 15 min)
  - Check CNAME is correctly configured
  - Verify domain added in Scaleway Console
  - Check SSL certificate status

- **CNAME shows wrong value**:
  - Some DNS providers append domain automatically
  - Try using just `blog` instead of `blog.example.com`

### Performance Issues

- **Slow Admin Panel**:
  - Increase memory from 512MB to 1024MB
  - Check database node type (use db-play2-pico, not db-play2-pico)
  - Monitor CPU usage and increase if needed

- **Cold Starts**:
  - Set `min_scale = 1` to keep at least one instance running
  - Trade-off: higher costs but no startup delay

## Architecture Overview

```
┌─────────────────┐
│   DNS Provider  │
│ (CNAME: blog)   │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Scaleway Serverless Container      │
│  ghost-blog.fnc.scw.cloud           │
│                                     │
│  ┌──────────────────────────────┐  │
│  │  Ghost (Docker Container)    │  │
│  │  - Port 2368                 │  │
│  │  - Auto-scaling (1-5)        │  │
│  │  - 1vCPU, 1GB RAM           │  │
│  └──────────────────────────────┘  │
└────┬──────────────────────┬─────────┘
     │                      │
     ▼                      ▼
┌─────────────┐    ┌──────────────────┐
│  MySQL 8    │    │  S3 Object Store │
│  (Managed)  │    │  (Public Bucket) │
│  [Private]  │    │                  │
│  - Backups  │    │  - Images        │
│  - SSL/TLS  │    │  - Themes        │
│  - db-play2-pico  │    │  - Files         │
└─────────────┘    └──────────────────┘
```

## Cost Estimation

**Monthly costs** (approximate):

- **Serverless Container** (min_scale=1): ~€10-15/month
- **MySQL db-play2-pico**: ~€25-30/month
- **Object Storage**: ~€0.01/GB + requests
- **Container Registry**: Free tier usually sufficient

**Total**: ~€35-50/month for a low-traffic blog

**Cost Optimization**:

- Set `min_scale = 0` for dev/staging (cold starts acceptable)
- Use db-play2-pico for non-production (~€10/month instead of €25)
- Clean up old container images from registry

## Configuration Details

### Ghost Environment Variables (Container)

The serverless container is configured with the following Ghost settings:

**Authentication & Security**:

- `security__staffDeviceVerification = false` - Disables 2FA device verification (required if email not configured)
- `session__secure = true` - Enables secure cookies (HTTPS only)
- `session__sameSite = "Lax"` - Cross-site cookie policy
- `session__trust_proxy = true` - Trusts X-Forwarded-* headers from proxy (required for Scaleway serverless)
- `session__path = "/"` - Session cookie path configuration

**Mail Configuration**:

- `mail__from` - Sender email address for Ghost notifications
  - If not specified: Auto-generates based on custom domain or default container URL
  - Example: `"noreply@blog.example.com"`

**Database & Storage**:

- Database passwords auto-generated and stored securely
- S3 credentials stored in Scaleway Secret Manager
- MySQL with SSL/TLS enforced
- S3 bucket with CORS configured

**Important Notes**:

- The `security__staffDeviceVerification = false` setting disables Ghost's 2FA feature
- If you want to enable 2FA in the future, you **must** configure a mail transport (Mailgun, SendGrid, SMTP, etc.)
- For serverless environments, `session__trust_proxy = true` is essential for proper session handling

## Security Best Practices

✅ **Implemented**:

- Database passwords auto-generated and stored securely
- Secrets stored in Scaleway Secret Manager
- SSL/TLS enforced on database connections
- S3 access via IAM with minimal permissions
- Container registry is private
- Database uses Private Network (VPC) for enhanced security
- Session security configured for proxy environments
- Device verification disabled (email required for 2FA)

⚠️ **Important Note on S3 Visibility**:
The S3 bucket used for storing images and themes is configured with **public-read** access. This is required for Ghost to serve images directly to visitors. Do not store sensitive private data in this bucket, as the files can be accessed by anyone with the URL.

⚠️ **Additional Recommendations**:

- Regularly update Ghost version (rebuild Docker image)
- Enable database backups (enabled by default)
- Monitor access logs
- Implement rate limiting if needed
- **For Production**: Configure SMTP/Email and re-enable device verification by setting `security__staffDeviceVerification = true`

## Infrastructure Management

### Updating Infrastructure with Terraform

After making changes to your Terraform configuration:

```bash
cd terraform
terraform plan    # Review changes
terraform apply   # Apply updates
```

### Destroying Infrastructure

**⚠️ Warning**: This will delete the database, S3 bucket, and ALL data permanently!

```bash
cd terraform
terraform destroy
```

Before destroying, consider:

- Backup your database manually
- Download important images from S3
- Export your Ghost content (Settings > Labs > Export)

## Maintenance

### Updating Ghost Version

1. **Rebuild and push Docker image** with latest Ghost version:

   ```bash
   cd serverless-deployment
   docker build --platform linux/amd64 -t rg.fr-par.scw.cloud/<namespace>/ghost-s3:latest .
   docker push rg.fr-par.scw.cloud/<namespace>/ghost-s3:latest
   ```

2. **Redeploy** the container:
   - **With Terraform**: `cd terraform && terraform apply`
   - **Manually**: Scaleway auto-detects new image and redeploys

3. **Verify** at `https://blog.example.com/ghost`

### Database Backups

- **Automated backups**: Enabled by default (365-day retention)
- **Manual backup**: Scaleway Console > Database > Backups > Create Backup
- **Restore**: Scaleway Console > Database > Backups > Select backup > Restore
- **⚠️ Test restore** periodically to ensure backups work

### Monitoring & Logs

**Container Monitoring**:

```bash
# View logs with Terraform
cd terraform
terraform output container_url  # Get container name

# Then in Scaleway Console:
# Serverless > Containers > Your Container > Logs tab
```

**Monitor**:

- Container logs for application errors
- CPU and memory usage graphs
- Request count and response times
- Database connection status

**Set Up Alerts** (recommended):

- Scaleway Console > Observability > Alerts
- Alert on: High error rate, memory exhaustion, downtime

## 🎓 What You've Learned

Congratulations! You've successfully deployed a production-ready Ghost blog using serverless architecture. Here's what you accomplished:

✅ **Serverless Deployment**: Deployed an application that auto-scales based on traffic
✅ **Infrastructure as Code**: Used Terraform to automate cloud resource provisioning
✅ **Container Management**: Built and deployed Docker images to a container registry
✅ **Cloud Storage**: Configured S3-compatible object storage for persistent media files
✅ **Database Management**: Set up a managed MySQL database with automatic backups
✅ **DNS & SSL**: Configured a custom domain with automatic HTTPS certificates

## 🚀 Next Steps & Enhancements

Now that your blog is running, consider these improvements:

**Content & Design:**

- Customize your Ghost theme in the admin panel
- Import content from another platform (Settings > Labs > Import)
- Install premium Ghost themes

**Email Configuration:**

- Set up SMTP (Mailgun, SendGrid, or AWS SES) for email notifications
- Enable Ghost's built-in newsletter features
- Re-enable 2FA by setting [`security__staffDeviceVerification = true`](terraform/container.tf) (requires email)

**Performance & Monitoring:**

- Set up Scaleway Observability alerts for downtime monitoring
- Add a CDN (Cloudflare) for faster global content delivery
- Monitor database performance and optimize slow queries

**Advanced Infrastructure:**

- Set up staging environment using Terraform workspaces
- Implement blue-green deployments for zero-downtime updates
- Add backup automation scripts

**SEO & Analytics:**

- Install Ghost's native analytics or integrate Google Analytics
- Configure SEO metadata in Ghost settings
- Submit sitemap to Google Search Console

## 📚 Additional Resources

**Official Documentation:**

- [Scaleway Serverless Containers](https://www.scaleway.com/en/docs/serverless/containers/)
- [Ghost Documentation](https://ghost.org/docs/)
- [Ghost S3 Storage Adapter](https://github.com/colinmeinke/ghost-storage-adapter-s3)
- [Terraform Scaleway Provider](https://registry.terraform.io/providers/scaleway/scaleway/latest/docs)

**Community & Learning:**

- [Ghost Forum](https://forum.ghost.org/) - Get help with Ghost-specific questions
- [Scaleway Community](https://www.scaleway.com/en/community/) - Scaleway tutorials and discussions
- [Terraform Tutorials](https://developer.hashicorp.com/terraform/tutorials) - Learn more about Infrastructure as Code

**Support Channels:**

- **Ghost Issues**: [Ghost Forum](https://forum.ghost.org/)
- **Scaleway Issues**: [Scaleway Support](https://console.scaleway.com/support/tickets)
- **This Deployment**: Check the [troubleshooting section](#troubleshooting) above

## 📝 Tutorial Feedback

Found an issue or have suggestions for improving this tutorial? Consider:

- Opening an issue in the repository
- Contributing improvements via pull request
- Sharing your deployment experience

---

**Happy blogging! 🚀**
