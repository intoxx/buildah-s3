# What is it ?
Integrate buildah images with s3 buckets without any container registry.

**Push** and **pull** your images to the cloud in one single command, either locally or from a CI/CD pipeline.

It doesn't replace the need for a container registry but for simple projects it still provide access to reliable storage without any hassle (apart setting up your storage API keys).

# When to use it ?
- You want to store your images to re-use them later.
- You don't want to use an official container registry *(most free plans come with little storage).*
- You don't want to host and manage a container registry yourself.

# Dependencies
- buildah
- podman (to run [docker.io/amazon/aws-cli](amazon/aws-cli))

# Usage
```sh
S3_BUCKET=<bucket> S3_REGION=<region> S3_ENDPOINT=<endpoint> S3_KEY=<key> S3_SECRET=<secret> push <image:tag>
S3_BUCKET=<bucket> S3_REGION=<region> S3_ENDPOINT=<endpoint> S3_KEY=<key> S3_SECRET=<secret> pull <image:tag>
```
