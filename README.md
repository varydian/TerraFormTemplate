# Terraform Base Template Readme:

1. Background
2. Intended Use
3. Setup Instructions
4. Configuration Output
5. Pipelines, Git & Environments
6. Important Notes
7. FAQ

## 1. Background
Some background on why Terraform is awesome and why we use pipelines.

### Terraform
[Terraform](https://www.terraform.io/) is an open-source tool for creating, changing and managing software infrastructure.
Using a Terraform configuration you can, for example, set up an entire Azure environment at the push of a button. Resource groups, databases, networks, down to the level of keyvault secrets and actual applications. What's more, you can then manage this entire setup using the same configuration.
So if you've set up and managed your Test environment using Terraform, and are content with it, setting up your Acceptance (and Production) environment is simply a matter of running the same configuration with different variables. Powerful stuff!

### Terraform using pipelines
The simplest way to run a Terraform configuration is straight from the CLI, using a 'Terraform apply' command.
However, in this project we use Azure DevOps pipelines. This has the advantage of maintaining a strict and easy-to-review audit-trail. Any change to the Terraform configuration (and hence the infrastructure it manages) is represented as a change in the Git repository. Any actual application of the configuration is represented as a pipeline run. It will also allow strict access control. We warmly recommend following this structure when using Terraform in a client project.

### Terraform modules
Since Terraform allows you to build very large infrastructure setups with a single Terraform configuration, these can become very large. To ensure a configuration remains manageable and readable, it is advisable to split the configuration up into modules (and in extreme cases, split modules into submodules).
You can see examples of modules in this project. All key steps that the configuration executes (create Service Principal, Create Key Vault, Create Kubernetes Cluster) are represented as separate modules.
If you are going to create an extended configuration based on this template, it is recommended that you follow this modular structure.

### Terraform for testing
Terraform can set up an entire infrastructure with one click. This also makes it perfect for managing temporary resources, like an Azure environment you may want to experiment with every once in a while, but do not need to be up (and incurring cost) 24/7.
By 'applying' your Terraform configuration you can create the entire setup if and when you need it, and using Terraform's 'destroy' command, erase every trace of it just as easily. In fact, the 'Destroy' pipeline you can find in this repository includes a Cron trigger that will automatically run 'destroy' at the end of the day, just so you don't forget. Sweet no?

## 2. Intended Use
The 'Base Template' repository is exactly what its name would suggest: a very bare-bones Terraform configuration and pipeline setup, intended to be an easy starting point for new repositories. It offers easily understood examples of using Variables, Output, Modules etc. As well as how to set up the pipelines. We therefore request you only submit changes to *this* repository if they are improvements to the Base Template. If you want to tweak, expand or experiment with it, please clone this base to a new repository and go nuts.

## 3. Setup Instructions
This sections covers how to set up and run a version of the Terraform template for yourself.

### Terraform Resources
To run, Terraform itself requires some resources to be already present. Normally these will be manually created:

On Azure:
- __A Service Principal__ - The account Terraform will use to do its work. Requires sufficient access rights
- __A Storage Account__ - The place where Terraform can store it's State file

On Azure DevOps:
- __A Service Connection to the ARM__ - Used by Terraform to connect to the Azure Resource Manager
- __A Terraform Variable Group__ - Containing variables for Terraform itself, including the Storage Account info and the Service ARM
- __A project Variable Group__ - Containing variables that are specific to your Terraform configuration, like the name of the State file (should be unique) and Command Options

Terraform can use the same Service Principal and Storage Account for multiple configurations. Each will get its own State file. Do take care to define a *unique* name for your configuration's state file.

### Terraform Resources - using existing resources
If you simply want to experiment with Terraform configurations or want to use Terraform to create temporary resources you need for testing or experimentation, we recommend you create a new repository within the 'Terraform' project. This way, most of the aforementioned resources are already available, as they exist for our BaseTemplate project. This will save a fair bit of work.

All you need to do is:
- Clone this repository
- Clone the 'BaseTemplate' Variable Group under 'Pipelines' -> 'Library' in the Terraform project and rename it.
  - Change the 'backendAzureRmKey' value to an appropriate file app_name (do __not__ forget this, or another State file may be overwritten!)
  - Change the value of 'app-name' under the 'commandOptions' to an appropriate name for your project.
- Go into the repository -> 'pipelines'. Here you find the .yaml files that will create the pipelines. In these files, change all instances of 'BaseTemplate' to the name of your newly created Variable Group.

That's it. You're ready to create the pipelines and run the configuration. Skip to the section 'pipelines'.

### Terraform resources - DIY
If you're setting up a clone of this repository in a different Azure DevOps project or in a different Azure subscription, you will need to create some or all of the following resources mentioned manually.

If you want to use Terraform on a different subscription than "Microsoft Partner Network", you'll need to:
1. __Create a new Resource Group__ - This resource group will be exclusively for managing the resources that allow Terraform to function, so name it appropriately (example: rg-Terraform).
2. __Create a new Storage Account__ - Create it in the Resource Group you just created. Note that the name of the name of a Storage Account must be *unique* within a region. Easiest is to give it an appropriate name and attach a random integer. (example: saterraform235789).
3. __Create a new Container in the Storage Account__ - Go to the newly created Storage Account in Azure and create a new Container. Name it something like 'tfstate' as it will contain your Terraform state file(s).

In you want to use Terraform on a different Azure Subscription than "Microsoft Partner Network" or from a different Azure DevOps project than "FinapsTerraform > Terraform", you'll need to:
1. __Create a new Service Connection__ - Under 'Project Settings' of your Azure DevOps project, create a new Service Connection. Select 'Azure Resource Manager' as the connection type and use your Subscription to connect.
2. __Update Terraform Service Principal permissions__ - The permissions for the Service Principal that was created for the Service Connection will need to be adjusted. Select your new Service Connection and click 'Manage Service Principal'. In the next screen go to the 'API Permissions' tab and add the following (Legacy) "Azure Active Directory Graph" permissions. Admin Consent will need to be granted for both these permissions.
  
   - (Azure Active Directory Graph) Application.ReadWrite.OwnedBy
   - (Azure Active Directory Graph) User.Read

3. __Create Variable Group for Terraform__ - Under 'Pipelines' -> 'Library', create a new Variable Group called e.g. 'Terraform\<NameOfAzureSubscription\>'. This Variable Group will contain the variables that allow Terraform to manage resources on your subscription. Add the following variable keys and give them appropriate values:

   - __backendAzureRmResourceGroupName__ - Value: The name of the Resource Group you created earlier
   - __backendAzureRmStorageAccountName__ - Value: The name of the Storage Account you created earlier
   - __backendAzureRmContainerName__ - Value: The name of the container you created in the Storage Account earlier.
   - __backendServiceArm__ - Value: The name of the Service Connection you created earlier

In all cases, when creating a new Terraform repository, you'll need to:
1. __Create a Variable Group for your project__ - Under 'Pipelines' -> 'Library', create a new Variable Group. This Variable Group will contain the variables specific to your project, so our advice is to give it the same name as your project. Add the following variable keys and give them appropriate values:
   - __backendAzureRmKey__ - The name of .tfstate file that will be created for your project and stored in the Terraform Storage Account. Note that this variable should end with the '.tfstate' extension and should have a unique name within the container. If two projects use the same container and the same state file name, they will overwrite each other.
   - __commandOptions__ - The parameters you wish to pass to the Main Terraform configuration, as a single commandOptions string. Variables in this string should match with those listed in the Variables.tf of your main configuration. For the BaseTemplate, the commandOptions are: *-var="app_name=Terraform-base-template" -var="app_location=westeurope"*
   - __workingDirectory__ Working directory of your project. For the BaseTemplate this is simply 'terraform'
2. __Clone the BaseTemplate repository__ - Duh
   - __Change the Pipeline yaml files in the cloned repository__ - In the 'pipelines' folder of the project, there are several yaml files for the pipelines to be created. These reference the Variable Groups used by the BaseTemplate repository (BaseTemplate and TerraformMicrosoftPartnerSubscription). Rename these to your own newly created Variable Groups in all relevant yamls (apply, destroy, plan, validate).

### The Pipelines

Before creating or running any pipeline, make sure that the [Terraform Extension](https://marketplace.visualstudio.com/items?itemName=ms-devlabs.custom-terraform-tasks) is installed in your organization. For the FinapsTerraform organization, this has already been done.

To create the pipelines for your project, go to the 'pipelines' section of Azure DevOps and hit 'New pipeline'. In the next step, select the appropriate repository (Azure DevOps Git for our BaseTemplate project) and then select 'Existing Azure Pipeline Yaml file'.

This will allow you to select one of the yaml files in the 'pipelines' folder of the project.
Initially you will want to create three separate pipelines, using the following .yaml files:
- __Plan__ - Running this pipeline will cause Terraform to run a 'plan' command and output the result. This will show you exactly what Terraform will attempt to do when you run 'apply'. What resources will be created, what resources will be edited, etc. It is good practice to perform this step before any significant release
- __Apply__ - Running this pipeline will 'apply' the Terraform configuration. It will attempt to create or update all requested resources
- __Destroy__ - Running this pipelines will 'destroy' any resources created under the Terraform configuration. The BaseTemplate configuration also includes a Cron trigger, that will automatically run this configuration at 1900h. So even if you forget to remove your temporary resource, the pipeline will do it for you. Of course, if you use Terraform to create a non-temporary resource, *do remove this trigger!*

Note that the 'Plan' pipeline by default has 'master' as trigger. This means the pipelines will run automatically if a change on the master branch is detected. 'Apply' has no automatic trigger, and 'Destroy' only has a scheduled trigger. You can tweak this behavior to your own needs. For example, if you have a separate 'develop' branch, you can trigger the 'Plan' pipeline on develop, and 'Apply' on master. Or you can choose to trigger 'Apply' based on a tagged release. The latter is a neater solution for actual client projects.

We consider it to be good practice to rename the pipelines after creating them, where:

  - Folder Name = Repository Name
  - Pipeline Name = Apply | Destroy | Plan | Validate

### Validate Results
If you followed all steps correctly you now have three pipelines linked to your own repository. Run 'Plan' first to see if everything checks out. Output should indicate that a fair number of new resources will be created (for a clone of the BaseTemplate repository).
If this is the case, run the 'Apply' pipeline. This should create the resources using the app_name you provided in your Variable Group.
Verify in Azure that the resources are created and then use the 'Destroy' pipeline to clean them up.

### Next Steps
You now have working pipelines and a very basic configuration. Excellent! Of course, that's probably only the start. You can now start tweaking and expanding the configuration with extra resources like databases, a service bus, an nginx controller, etc.
Don't worry about experimenting a bit. If things get messy, there's always the 'Destroy' pipeline.

## 4. configuration output
The current BaseTemplate configuration will create the following resources:

- Azure
  - Service Principal
  - Resource Group: rg-{app_name}
    - Key Vault : kv-{hash(app_name)}
    - Kubernetes Cluster : aks-{app_name}
  - Resource Group: rg-{app_name}-k8s
    - Network Security Group
    - Route Table
    - Virtual Machine Scale Set
    - Virtual Network
    - Public IP Address
    - Load Balancer

It will also add the kubeconfig of the Kubernetes cluster to the KeyVault automatically.

Note that the second Resource Group 'rg-{app_name}-k8s' is created by Azure automatically when a Kubernetes Service is created. It contains the basic resources needed by the Kubernetes Cluster. Hence you will not find it explicitly in the configuration.

## 4. Pipelines, Git & Environments

### Automatic Deployment Strategy

While the Plan, Apply and Destroy pipelines could be executed manually at all times, this base template has been set up with a certain automatic deployment strategy in mind. The main idea is to use the ```.tfplan``` file resulting from the Plan pipeline to execute the Apply pipeline. This will ensure that the plan you have created and reviewed is the one that will actually be applied in the Apply pipeline. Put more concretely: when creating a Pull Request on master, the Plan Pipeline will be triggered as a branch policy. This plan can be reviewed until it is deemed 'done' after which the PR will be rebased onto Master. This will trigger the Apply Pipeline to be executed on Master, which will take the ```.tfplan``` file generated in the Plan Pipeline and execute it. See the schematic below for a visual representation of this idea:

```
Feature Branch
| (PR)          <- Plan Pipeline [triggered as Branch Policy]
|                         |
|                         | .tfplan Artifact
v                         v
Master Branch   <- Apply Pipeline [triggered on Master]
```

### Releasing to Multiple Environments

TODO

## 6. Important notes

### Resource management using Terraform
Terraform is intended not just to create resources, but also manage them. To this end, it keeps a memory of its state in State file. Consequently, if you manually manipulate or remove resources that are managed via Terraform, this can lead to unexpected results (similar to Helm configurations).

### TfState file names
It's been mentioned before but it bears repeating. Make sure that the .tfstate file name for your project's Terraform is *unique* within the Container. If multiple Terraform pipeline deployments use the same Storage Account -> Container -> {fileName}.tfstate, deployments will start to overwrite each other's state. Take care that this does not happen.


## 7. FAQ

### How To Use Terraform Output Variables in your Pipeline

The Apply Pipeline exports the variables defined in the ```terraform/output.tf``` file. These variables can be used in this pipeline for subsequent tasks. There are two different ways of doing this:

1. Use Variables in another step:

```yaml
jobs:
  - job: TerraformApply
    steps:
    - template: azure.yaml
      parameters:
        command: 'apply'
        ...        
    - bash: |
        echo "key vault: $(TerraformOutput.key_vault_name)"
```

2. Use Variables in another job:

```yaml
jobs:
  - job: TerraformApply
    steps:
    - template: azure.yaml
      parameters:
        command: 'apply'
        ...        
  - job: EchoKeyVault
    dependsOn: TerraformApply
    variables:
      keyVaultName: $[ dependencies.TerraformApply.outputs['TerraformOutput.key_vault_name'] ]
    steps:
      - bash: |
          echo "key vault: $(keyVaultName)"
```