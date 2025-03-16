#!/bin/bash

#############################################################################################################################
#DESCRIPTION																												#
#	Loads Azure Key Vault secrets into Tofu environment variables for the current bash session.								#
#																															#
#    The following steps are automated:																						#
#    - Identifies the Azure Key Vault matching a search string (default: 'terraform-kv').									#
#    - Retrieves the Terraform secrets from Azure Key Vault.																#
#    - Loads the Terraform secrets into these environment variables for the current bash session:							#
#        - ARM_SUBSCRIPTION_ID																								#
#        - ARM_CLIENT_ID																									#
#        - ARM_CLIENT_SECRET																								#
#        - ARM_TENANT_ID																									#
#        - ARM_ACCESS_KEY																									#
#																															#
#VERSION 3.0.1																												#
#																															#
#EXAMPLE																													#
#    source ./wrgcli.sh																			#
#                                                                             												#	
#    Loads Azure Key Vault secrets into Terraform environment variables for the current bash session						#
#																															#
#NOTES																														#
#    Assumptions:																											#
#    - Az Cli install																										#
#	 - You are inside a zsh/bash session																					#
#    - You are already logged into Azure before running this script (eg. az account login)									#
#	 - Opentufu is installed																								#
#																															#
#    Author:  SFibich																										#	
#    GitHub:  https://github.com/westridgegroup																				#
#																															#
#    This script was modeled after Adam Rush's script LoadAzureTerraformSecretsToEnvVars.ps1 https://github.com/adamrushuk.	#
#																															#
#############################################################################################################################
echo "sourcing wrgcli.sh"
echo "wrg_help for help"

YELLOW='\033[0;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color
OPTIND=1
while getopts :m:f:k:r:s: flag
do
    case "${flag}" in
		f) ENV_FILE=${OPTARG};;
        k) USER_KEY_VAULT_PATTERN=${OPTARG};;
        r) USER_RESOURCE_GROUP=${OPTARG};;
        s) USER_SUBSCRIPTION=${OPTARG};;
		?) SKIP=TRUE 
			echo "help: switches -f ENV_FILE -k USER_KEY_VAULT_PATTERN -r USER_RESOURCE_GROUP -s USER_SUBSCRIPTION" ;;
    esac
done

alias faa=' (print -rlo ${(k)functions} ${(k)aliases} )'
alias tofu_help=' (faa | grep ^tofu)'

function wrg_help(){
	echo "Welcome to the WRG client!"
	echo ""
	echo "Sub-topic help commands:"
	echo "tofu_help - help with the Open Tofu client commands"
	echo ""
	tofu_help
}

function tofu_read_env_file() {
	echo "ENV FILE: $ENV_FILE"
	a=$(grep state_container_name $ENV_FILE)
	b=$(echo $a | tr -d "=")
	c=${b#state_container_name}
	d=$(echo $c | tr -d '"')
	e=${d##*( )};
	STATE_CONTAINER_NAME=$e

	f=$(grep state_key $ENV_FILE)
	g=$(echo $f | tr -d "=")
	h=${g#state_container_name}
	i=$(echo $h | tr -d '"')
	j=${i##*( )};
	STATE_KEY=$j
	
	echo "STATE_CONTAINER_NAME: $STATE_CONTAINER_NAME"
	echo "STATE_KEY: $STATE_KEY"
}

function tofu_set_core_variables() {

if [ -z "$USER_KEY_VAULT_PATTERN" ]
	then
		KEY_VAULT_NAME_PATTERN=terraform-kv
		echo "Using Default KEY_VAULT_NAME_PATTERN:$KEY_VAULT_NAME_PATTERN"
	else
		KEY_VAULT_NAME_PATTERN=$USER_KEY_VAULT_PATTERN
		echo "Using input KEY_VAULT_NAME_PATTERN: $KEY_VAULT_NAME_PATTERN"
fi

if [ -z "$USER_RESOURCE_GROUP" ]
	then
		TERRAFORM_RESOURCE_GROUP=terraform-mgmt-rg
		echo "Using Default TERRAFORM_RESORUCE_GROUP:$TERRAFORM_RESOURCE_GROUP"
	else
		TERRAFORM_RESOURCE_GROUP=$USER_RESOURCE_GROUP
		echo "Using input TERRAFORM_RESOURCE_GROUP:$TERRAFORM_RESOURCE_GROUP"
fi


}


function tofu_get_keyvault_values() {

#####################
#Check Azure login	#
#####################
echo "Checking for an active Azure login..."

CURRENT_SUBSCRIPTION_ID=$(az account list --query "[?isDefault].id" --output tsv)

if [ -z "$CURRENT_SUBSCRIPTION_ID" ]
	then 
		printf '%s\n' "ERROR! Not logged in to Azure. Run az account login" >&2
#		exit 1
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

#####################
#Get Azure Key Vault#
#####################
echo "Searching for Terraform KeyVault..."
KEY_VAULT_NAME=$(az keyvault list --resource-group $TERRAFORM_RESOURCE_GROUP --query "[?contains(name,'$KEY_VAULT_NAME_PATTERN')].name" --output tsv)

if [ -z "$KEY_VAULT_NAME" ]
	then
		printf '%s\n' "ERROR! No Azure Key Vault with name pattern like $KEY_VAULT_NAME_PATTERN" >&2
#		exit 1
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

#############################
#Get Azure KeyVault Secrets	#
#############################
echo "Loading ARM_SUBSCRIPTION_ID..."
ARM_SUBSCRIPTION_ID=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name ARM-SUBSCRIPTION-ID --query "value" --output tsv)
if [ -z "$ARM_SUBSCRIPTION_ID" ]
	then 
		printf '%s\n' "FAILURE! Azure Key Vault missing secret ARM-SUBSCRIPITON-ID" >&2
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

echo "Loading ARM_CLIENT_ID..."
ARM_CLIENT_ID=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name ARM-CLIENT-ID --query "value" --output tsv)
if [ -z "$ARM_CLIENT_ID" ]
	then 
		printf '%s\n' "FAILURE! Azure Key Vault missing secret ARM-CLIENT-ID" >&2
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

echo "Loading ARM_CLIENT_SECERT"
ARM_CLIENT_SECRET=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name ARM-CLIENT-SECRET --query "value" --output tsv)
if [ -z "$ARM_CLIENT_SECRET" ]
	then 
		printf '%s\n' "FAILURE! Azure Key Vault missing secret ARM-CLIENT-SECRET" >&2
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

echo "Loading ARM_TENANT_ID..."
ARM_TENANT_ID=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name ARM-TENANT-ID --query "value" --output tsv)
if [ -z "$ARM_TENANT_ID" ]
	then 
		printf '%s\n' "FAILURE! Azure Key Vault missing secret ARM-TENANT-ID" >&2
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

echo "Loading ARM_ACCESS_KEY..."
ARM_ACCESS_KEY=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name ARM-ACCESS-KEY --query "value" --output tsv)
if [ -z "$ARM_ACCESS_KEY" ]
	then 
		printf '%s\n' "FAILURE! Azure Key Vault missing secret ARM-ACCESS_KEY" >&2
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

echo "Loading DATABRICKS_ACCOUNT_ID..."
DATABRICKS_ACCOUNT_ID=$(az keyvault secret show --vault-name $KEY_VAULT_NAME --name DATABRICKS-ACCOUNT-ID --query "value" --output tsv)
if [ -z "$DATABRICKS_ACCOUNT_ID" ]
	then 
		printf '%s\n' "FAILURE! Azure Key Vault missing secret DATABRICKS_ACCOUNT_ID" >&2
	else
		echo "${YELLOW}SUCCESS!${NC}"
fi

}



function tofu_get_backend_values() {

	BACKEND_STORAGE_ACCOUNT=$(az storage account list --resource-group $TERRAFORM_RESOURCE_GROUP --query "[?contains(@.name, 'terraform')==\`true\`].name" --output tsv)
}


function tofu_output_info() {
	echo "************************************************************************"
	echo "                              SPN VALUES"
	echo "************************************************************************"
	echo "ARM_SUBSCRIPTION_ID: $ARM_SUBSCRIPTION_ID"
	echo "ARM_CLIENT_ID:       $ARM_CLIENT_ID"
	echo "ARM_CLIENT_SECRET:   HIDDEN!"
	echo "ARM_TENANT_ID:       $ARM_TENANT_ID"
	echo "ARM_ACCESS_KEY:      $ARM_ACCESS_KEY"
	echo "DATABRICKS_ACCOUNT_ID:" $DATABRICKS_ACCOUNT_ID
	echo "************************************************************************"
	echo ""
	export ARM_CLIENT_ID
	export ARM_CLIENT_SECRET
	export ARM_TENANT_ID
	export ARM_SUBSCRIPTION_ID
	export ARM_ACCESS_KEY
	export TF_VAR_arm_client_id=$ARM_CLIENT_ID
	export TF_VAR_arm_client_secret=$ARM_CLIENT_SECRET
	export TF_VAR_arm_tenant_id=$ARM_TENANT_ID
	export TF_VAR_databricks_account_id=$DATABRICKS_ACCOUNT_ID

}

function tofu_init() {
	
	TOFU_INIT="tofu init --backend-config='storage_account_name=$BACKEND_STORAGE_ACCOUNT' --backend-config='key=$STATE_KEY' --backend-config='container_name=$STATE_CONTAINER_NAME' --reconfigure"
	echo "Running: $TOFU_INIT"

	bash -c $TOFU_INIT

}
#####################
#		MAIN		#
#####################
function tofu_setup() {
	ENV_FILE=$1
	echo "ENV_FILE is $ENV_FILE"
	tofu_set_core_variables
	tofu_get_keyvault_values
	tofu_get_backend_values
	tofu_read_env_file
	tofu_output_info
	tofu_init

	echo "FINISHED!"
}

function tofu_plan() {
	eval "tofu plan -var-file $ENV_FILE -out terraform.plan"
}

function tofu_apply() {
	eval "tofu apply terraform.plan" 
}

function tofu_destroy() {
	eval "tofu apply -destroy -var-file $ENV_FILE" 
}