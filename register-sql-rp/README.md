## Automatically Register Azure SQL IaaS Resource Provider
---

The following deployment will automatically register the [Microsoft.SQLVirtualMachine](https://docs.microsoft.com/en-us/azure/templates/microsoft.sqlvirtualmachine/sqlvirtualmachines?tabs=json) resource provider for all subscriptions in a specified management group hierarchy. This process ensures automatic compliance of SQL IaaS AHUB licensing for SQL along with providing additional benefits for SQL management inside an Azure VM.

The deployment creates the following:

- Custom RBAC Role with the following permissions
    -   Microsoft.SqlVirtualMachine/register/action
    -   Microsoft.Features/providers/features/register/action
    -   Microsoft.Resources/subscriptions/read
- Azure PowerShell Function with once a week run trigger
- Azure Function Service Principal
- Role Assignment of Service Principal with custom RBAC role scoped to a management group


## SQL virtual machine


Registering SQL Server on Azure virtual machines (VMs) with the SQL VM resource provider has [several advantages](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-server-iaas-agent-extension-automate-management?tabs=azure-powershell#feature-benefits) including monitoring and manageability capabilities (such as automated patching and automated backup), as well as unlocking licensing and edition flexibility. The capabilities provided will expand over time as Microsoft will continue to add new benefits over time.


## Automatic SQL VM resource provider registration


The automatic registration of a subscription will register all currently available SQL VMs with the SQL VM resource provider in lightweight mode as well as any SQL VMs deployed to the subscription in the future. This process does not restart the SQL Server service. Manually upgrading to full manageability mode is recommended to take advantage of the full feature set.

---

## EULA

> I accept the terms in the agreement
> By clicking "Deploy to Azure", I confirm that I have authority to enter into agreements on behalf of the above subscription ID, and I consent to allow Microsoft to access SQL Server environment information on all Azure Virtual Machines belonging to the subscription ID's in the selected Management Group hierarcy.Furthermore I permit Microsoft to register all SQL Server instances with the SQL VM resource provider as [described here](https://docs.microsoft.com/en-us/azure/azure-sql/virtual-machines/windows/sql-agent-extension-automatic-registration-all-vms?tabs=azure-cli#overview).
> To learn more about SQL Server data processing and privacy controls, please see the [SQL Server Privacy Supplement](https://docs.microsoft.com/en-us/sql/sql-server/sql-server-privacy?view=sql-server-ver15).


[![Deploy to Azure](https://aka.ms/deploytoazurebutton)](https://portal.azure.com/#blade/Microsoft_Azure_CreateUIDef/CustomDeploymentBlade/uri/https%3A%2F%2Fraw.githubusercontent.com%2Fedm-ms%2Fpoc%2Fmain%2Fregister-sql-rp%2Fazuredeploy.json)

