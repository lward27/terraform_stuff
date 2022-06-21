## Terraform Stuff
Run: terraform init
this will download all the providers listed in any .tf file, it also creates a lock file

Run: terraform plan
this will do a "dry run" which outputs all the stuff that is gonna be made, changed, or destroyed. You can save the output if you want.

Run: export TF_VAR_AWS_REGION="us-east-1"
Creates environment variables for terraform (versus storing them in a tfvars file)

Run: terraform apply
this will build the infrastructure

Run: terraform apply - target {type}.{name}
this will build / destroy specific resources

Run: terraform refresh
this will refresh state and run output without deploying

Run: terraform state list
this will show you all of the pieces of the infrastructure

Run: terraform state show {type}.{name}
this will show you detailed information about specific resources

Run: terraform output
show all outputs from the config

Run: terraform apply -var "subnet_prefix=10.0.100.0/24"
Pass variables as command line arguments

Run: terraform apply -var-file {file_name}.tfvars
This will allow you to use a different tfvars file, naming 
the file terraform.tfvars will make it default without this 
option

Create a file caled {file_name}.tf to store your terraform declaritive configuration

Create a file called terraform.tfvars to store variables for
your configuration

Note: tf file is where you "define", tfvars file is where you
"assign" variables.