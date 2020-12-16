Code to build a fully automated Jenkins instance


1. Create a file called ./.credz as follow:

```
export AWS_SECRET_ACCESS_KEY=<credential>
export AWS_ACCESS_KEY_ID=<credential>
```

2. Run packer

```
source .credz && \
cd jenkins/master && \
packer build packer.json
````