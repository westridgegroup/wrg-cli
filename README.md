# wrgcli: 
### Enterprise grade built for the individual 

## Intro 
The wrgcli is a set of bash scripts meant to aid developers and operation personel in managment of the enviorment.  This client wraps a number of well known tools with the guidance from Westridge Group to make tasks easier and faster to complete.  


## Requirements

- The AZ CLI
- An Azure Subscription
- Bash/Z Shell

## Contents

- [Intro](#intro)
- [Requirements](#requirements)
- [Inital Setup](#inital-setup)
- [Bootstrapping](#bootstrapping)
- [Scripts](#scripts)

## Initial Setup 
(once per subscription) 

```{r, engine='sh', count_lines}
az login --use-device-code
./ConfigureAzureForSecureTerraformAccess.sh
```

## Bootstrapping
The wrgcli provides an enterprise-ready backend for open-tofu using Azure resources.   Using the bootstraping mechanisms of the wrgcli, moves your open-tofu state files to Azure Storage and uses an App Registration Client Id and Client Secret for authorization to Azure.  This allows you to decouple the permissions from your account to that of the App Registration.  It also allows you to share state files across your organization with other developers or CICD pipelines.  Lastly, it allows you to release the same terraform code to different environments without overwriting state files and without modifying the terraform code or having some sort of pre-execution replacement script run.


![wrgcli-azure-bootstrap](./wrgcli-azure-bootstrap.png)


(per project/environment switch)

```
az login --use-device-code
source wrgcli.sh
tofu_setup env/dev.tfvars
tofu_plan
tofu_apply
```

## Scripts

### ConfigureAzureForSecureTofuAccess.sh

The script creates a resource group, a key vault, a storage account, and an SPN.  It loads the client id, client secret, tenant id, subscription id, and storage account access key into the key vault. Next, the script grants the current user ownership over the key vault. Finally, it uses the current subscription the user is logged into to create the resources.

### TerraformAzureBootStrap.sh

The script loads information based on the account logged into Azure.  It expects the default subscription to contain a key vault named terraform-kv and a storage account named something that ends in terraform all within the resource group called terraform-mgmt-rg.  The ConfigureAzureForSecureTerraformAccess creates these objects. So, if that script has been previously executed, the required objects should exist.  The script then pulls the required azurerm configuration information from the key vault.  It also expects a tfvars file passed to it, which is the environment file for the project.  This file defines the terraform azurerm container_name and key for terraform state information.  The same tfvars file can contain other environment-specific variables for the project as well.  Using this script allows you to use the same terraform script for multiple environments without changing remote state values or worrying about overwriting state information. 
