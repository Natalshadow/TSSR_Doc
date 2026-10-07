
# AGDLP Explained: The Foundation of Role-Based Access Control in Active Directory

9 April 2026 by [fniesen](https://www.infrastructureheroes.org/author/fniesen/ "View all posts by fniesen")

This basic article on the AGDLP principle and the fundamentals of role and permission concepts is aimed not only at newcomers to these topics, but also at experienced IT system administrators who do not work with the design of Active Directory environments on a daily basis. It also forms the foundation for articles that help build a secure Active Directory based on German [IT Baseline Protection](https://www.infrastructureheroes.org/microsoft-infrastructure/what-is-the-german-it-baseline-protection-it-grundschutz/).

[Read more: AGDLP Explained: The Foundation of Role-Based Access Control in Active Directory](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/)

The AGDLP principle (Account, Global group, Domain local group, Permission) from Microsoft is a proven method for managing and delegating permissions in Active Directory environments. It is Microsoft’s standard approach for Role Based Access Control (RBAC), meaning role-based permissions. It provides a structured way to control access to resources efficiently and securely. By separating user accounts and permissions, AGDLP enables flexible and scalable permission management. In this article, I explain the AGDLP principle, highlight its importance, and discuss its specific impact in single-domain, single-forest, and multi-domain environments.

Table of Contents

- [What is the AGDLP principle in detail?](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#what_is_the_agdlp_principle_in_detail)
- [Active Directory group types](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#active_directory_group_types)
    - [AGDLP principle and universal groups](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#agdlp_principle_and_universal_groups)
- [Why is the AGDLP principle important?](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#why_is_the_agdlp_principle_important)
- [Further advantages of the AGDLP principle](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#further_advantages_of_the_agdlp_principle)
- [Example application of a role and permission concept](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#example_application_of_a_role_and_permission_concept)
    - [Additional tips for creating role and permission concepts](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#additional_tips_for_creating_role_and_permission_concepts)
- [Effects on different structures in Active Directory](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#effects_on_different_structures_in_active_directory)
    - [Single domain, single forest](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#single_domain_single_forest)
    - [Multi-domain environments](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#multi-domain_environments)
- [My personal conclusion](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#my_personal_conclusion)
- [Translation Notice](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/#translation_notice)

## What is the AGDLP principle in detail?

- Accounts (A): Individual user accounts or computer accounts in an organization.
- Global groups (G): Global groups that group user accounts by function, department, or other criteria. These groups are also referred to as role groups.
- Domain local groups (DL): Domain local groups that are used to manage permissions within a domain. They can contain global groups from the same domain or from other domains, from the same forest or through trusts. These groups are also referred to as permission groups.
- Permissions (P): Specific permissions granted to a domain local group for a resource.

![ADGDlP AGDLP Explained: The Foundation of Role-Based Access Control in Active Directory 1](https://infrastrukturhelden.de/wp-content/uploads/2024/03/ADGDlP.png "AGDLP Explained: The Foundation of Role-Based Access Control in Active Directory 2")

## Active Directory group types

|**Type (Scope)**|**Possible members**|**Can grant permissions in**|**Can be a member of**|
|---|---|---|---|
|**Universal**|Accounts from any domain within the same forest  <br>  <br>Global groups from any domain within the same forest  <br>  <br>Other universal groups from any domain within the same forest|Any domain in the forest or in trusted domains or forests|Other universal groups within the same forest  <br>  <br>Domain local groups within the same or a trusted forest  <br>  <br>Computer local groups within the same or a trusted forest|
|**Global**|Accounts within the same domain  <br>  <br>Other global groups within the same domain|Any domain in the forest or in trusted domains or forests|Universal groups from any domain within the same forest  <br>  <br>Other global groups from the same domain  <br>  <br>Domain local groups from any domain within the same forest or from a trusted domain|
|**Local (in domain)**|Accounts from any domain or a trusted domain  <br>  <br>Global groups from any domain or a trusted domain  <br>  <br>Universal groups from any domain within the same forest  <br>  <br>Other local groups from the same domain  <br>  <br>Accounts, global and universal groups from other forests and external domains|Within the domain|Other domain local groups from the same domain  <br>  <br>Local groups on computers within the same domain, excluding built-in groups with fixed security identifiers (SIDs)|

Differences between Active Directory groups

### AGDLP principle and universal groups

Many administrators like to use them because they are more flexible when it comes to nesting. But in many environments, that flexibility is more of a disadvantage. I only use them in very complex domains and forests where I really need them. To put that into perspective, in more than 20 years of AD consulting, this has applied to less than 5 percent of my customers.

There is also a variation of the AGDLP principle called AGUDLP. In this model, the global groups, meaning the roles of the individual domains, are first consolidated into universal groups before those are added to the permission groups of the respective domains.

## Why is the AGDLP principle important?

The AGDLP principle is the foundation for many role and permission concepts based on Active Directory. Since Active Directory is the central point for user authentication in many environments, for example VMware management environments such as vSphere, Linux systems, or enterprise firewalls use AD users for authentication, this foundation is particularly important. Unfortunately, many IT professionals have forgotten it.

[](https://techsmith.z6rjha.net/c/1600104/489441/5161)![](https://techsmith.z6rjha.net/i/1600104/489441/5161?gdpr=1&gdpr_consent=CQrt3MAQrt3MAFDADDENCzFgAAAAAEPAAAYgAAAOLgCAA8AWiAvMBxYAAAAA.IHFwBwAeAFbAWiAvMBjIDZgHFgAA.YAAAAAAAAAAA)

Now there are IT professionals who believe that a role and permission concept, and therefore also the AGDLP principle, is not relevant to them. However, German IT Baseline Protection, status 2023, states the following in OPS.1.1.1.A2 Definition of roles and permissions for IT operations: “For all operated IT components, the respective role and permission concept MUST also define roles and corresponding permissions for IT operations. …”. Because this is a basic requirement, it cannot be ignored when working according to German IT Baseline Protection. The topic also runs through many other measures and modules. Anyone who thinks this is not interesting should take a look at the article “What is German IT Baseline Protection”, with particular attention to NIS2. I have also heard that some cyber insurance providers now require not only an IT security concept but also a role and permission concept.

## Further advantages of the AGDLP principle

There are several additional advantages that help in daily work with an AGDLP-based environment in IT:

- Because of the clear structures, groups can be reviewed easily and can also be displayed in dashboards for auditors or IT security officers. For example:
    
    - Do domain local groups contain users or computers? => Security violation against the role and permission concept
    
    - Are permissions assigned directly to a global group? => Security violation against the role and permission concept
- Clear separation in larger environments. In an environment with multiple domains, the permission groups, meaning domain local groups, remain within the domain. This is a security benefit for management and control over the members that receive permissions through this group. These members, meaning role groups, can come from different domains if an appropriate trust exists.
- Easier changes of responsibilities without having too few or too many rights:
    
    - The helpdesk gets a new task? Simply add the Helpdesk role group to the corresponding permission group. Users no longer have to be adjusted individually.
    
    - A user changes department and therefore roles? Simply assign new role groups and remove membership in the old ones. Even if some roles remain, for example first aider, you do not have to check every single group membership to see whether the employee still needs it.
- More transparent environments, especially for audits and reviews. Every role has a collection of permissions. Every employee has one or more roles. This makes it relatively easy to determine which rights an employee has.

## Example application of a role and permission concept

Here is an example of a role and permission model that can serve as a starting point for a proper role and permission concept.

First, the roles are defined. What does someone with that role need in order to fulfill the tasks? Here are some fictional examples:

![RBAC AGDLP Explained: The Foundation of Role-Based Access Control in Active Directory 3](https://infrastrukturhelden.de/wp-content/uploads/2024/03/RBAC.png "AGDLP Explained: The Foundation of Role-Based Access Control in Active Directory 4")

Role “Editor for InfrastrukturHelden.de”

- Read and write access to the project directory
- Editor access to the InfrastrukturHelden.de WordPress blog

Role “Employee at the Remagen site”

- Read and write access to the site drive
- Access to the Wi-Fi
- Access to the printer

In the next step, the corresponding permission groups must be identified or created if necessary and assigned permissions. In this example:

Role “Editor for InfrastrukturHelden.de” (OG-PRJ-Infra_Redakteur)

- RG-FIL-IFH_RW
- RG-WEB-IFH_RE

Role “Employee at the Remagen site” (OG-LOC-Remagen)

- RG-FIL-REM_RW
- RG-SEC-REM
- RG-PRN-REM_C

### Additional tips for creating role and permission concepts

If you want to create a role and permission concept without working through the entire German IT Baseline Protection framework, here are some practical tips:

- Create a clear [naming concept for your IT environments](https://infrastrukturhelden.de/microsoft-infrastruktur/microsoft-windows/server/namenskonzepte-fuer-it-umgebungen/) that also allows you to distinguish the types of groups.
- Separate user accounts from administrator accounts. This means your IT staff should have at least two user accounts: one for office work, without local admin rights, and one for IT administration.
- Local administrative permissions are also administrative permissions. If employees need local admin rights, create a separate administrative account for that as well.
- Always assign the least possible privileges, including for service accounts. A service account does not need Domain Admin rights. If it does, the vendor was just too lazy to do the job properly. You are welcome to quote me on that.
- Use Group Managed Service Accounts (gMSA) instead of normal service accounts wherever possible.
- Differentiate administration into levels, even if that means some IT employees have to work with four or more user accounts. This is also called administrative levels or tiering and is the foundation for further hardening.
    
    - Level 0: Administration at domain level, Domain Admin
    
    - Level 1: Administration at server or service level, Server Admin
    
    - Level 2: Administration at endpoint level, Computer Admin
- Automate user creation, for example with PowerShell. You can find an example in the article “[Creating users easily with PowerShell](https://infrastrukturhelden.de/microsoft-infrastruktur/office-365/benutzer-einfachen-anlegen-mit-powershell/)”.

I will write a separate article on administrative levels or tiering when I get the chance.

## Effects on different structures in Active Directory

In Active Directory there are two major boundaries, the domain and the forest. Every domain belongs to exactly one forest. Every forest contains at least one domain. Many people still see the domain as a hard security boundary in an Active Directory environment, but unfortunately that is not correct. The real security boundary is the forest. Inside that forest, it may be harder to compromise another domain, but it is still easier because the attacker is already inside the outer boundary. Accordingly, for secure environments I always plan “one domain in one forest”, in English “single domain / single forest”. However, since this is not feasible or sensible in every environment, for example in mergers, this should always be kept in mind.

### Single domain, single forest

In such an environment, the AGDLP principle is relatively easy to implement and manage. All user accounts, global groups, and domain local groups are located within the same domain and the same forest, which simplifies the management of permissions and group memberships.

### Multi-domain environments

Applying the AGDLP principle in a multi-domain or multi-forest environment requires more careful planning and implementation. Additional challenges come into play here, such as trusts between domains and the management of global groups across domain boundaries. In such environments, it is especially important to define a clear structure and naming convention for groups in order to maintain clarity and manageability. The use of global groups can be necessary in multi-domain environments to consolidate users from different domains, while domain local groups continue to be used for assigning permissions within individual domains.

## My personal conclusion

The AGDLP principle is the foundation for RBAC and therefore also for role and permission concepts. Unfortunately, many people still underestimate this simple foundation today. That is also reflected in Microsoft’s increasingly cloud-focused training, but Microsoft says “this is the way”. Good thing there is often more than one path to the goal.

A tip regarding the hardening of Windows clients and endpoints: the BSI has published some useful guidance here. Take a look at the article “BSI security recommendations for Windows 10”.

---

## Translation Notice

This article is an AI-based English translation of the original German article published on InfrastrukturHelden.de. It is provided to make the content more accessible to an international audience. In case of ambiguities, differences in wording or translation-related inaccuracies, the original German version on InfrastrukturHelden.de is the authoritative version. Technical details, recommendations and assessments should therefore always be verified against the German original.

---

- [](https://twitter.com/intent/tweet?url=https%3A%2F%2Fwww.infrastructureheroes.org%2Fmicrosoft-infrastructure%2Factive-directory%2Fagdlp-explained-the-foundation-of-role-based-access-control-in-active-directory%2F&text=AGDLP%20Explained%3A%20The%20Foundation%20of%20Role-Based%20Access%20Control%20in%20Active%20Directory "Share on X (Twitter)")
- [](https://www.linkedin.com/sharing/share-offsite/?url=https%3A%2F%2Fwww.infrastructureheroes.org%2Fmicrosoft-infrastructure%2Factive-directory%2Fagdlp-explained-the-foundation-of-role-based-access-control-in-active-directory%2F "Share on LinkedIn")
- [](https://www.xing.com/spi/shares/new?url=https%3A%2F%2Fwww.infrastructureheroes.org%2Fmicrosoft-infrastructure%2Factive-directory%2Fagdlp-explained-the-foundation-of-role-based-access-control-in-active-directory%2F "Share on XING")
- [](https://www.facebook.com/sharer/sharer.php?u=https%3A%2F%2Fwww.infrastructureheroes.org%2Fmicrosoft-infrastructure%2Factive-directory%2Fagdlp-explained-the-foundation-of-role-based-access-control-in-active-directory%2F "Share on Facebook")
- [](https://api.whatsapp.com/send?text=https%3A%2F%2Fwww.infrastructureheroes.org%2Fmicrosoft-infrastructure%2Factive-directory%2Fagdlp-explained-the-foundation-of-role-based-access-control-in-active-directory%2F%20AGDLP%20Explained%3A%20The%20Foundation%20of%20Role-Based%20Access%20Control%20in%20Active%20Directory "Share on Whatsapp")
- [](https://www.pinterest.com/pin/create/link/?url=https%3A%2F%2Fwww.infrastructureheroes.org%2Fmicrosoft-infrastructure%2Factive-directory%2Fagdlp-explained-the-foundation-of-role-based-access-control-in-active-directory%2F&media=https%3A%2F%2Finfrastrukturhelden.de%2Fwp-content%2Fuploads%2F2024%2F03%2FADGDlP.png&description=AGDLP%20Explained%3A%20The%20Foundation%20of%20Role-Based%20Access%20Control%20in%20Active%20Directory "Pin it on Pinterest")
- 
- [](http://ct.de/-2467514 "More information")

Categories [Active Directory](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/) Tags [Active Directory](https://www.infrastructureheroes.org/topic/active-directory/), [Active Sync](https://www.infrastructureheroes.org/topic/active-sync/), [AGDlP](https://www.infrastructureheroes.org/topic/agdlp/), [AGUDLP](https://www.infrastructureheroes.org/topic/agudlp/), [APP.2.2](https://www.infrastructureheroes.org/topic/app-2-2/), [IT Baseline Protection](https://www.infrastructureheroes.org/topic/it-baseline-protection/), [OPS.1.1.1](https://www.infrastructureheroes.org/topic/ops-1-1-1/), [OPS.1.1.1.A2](https://www.infrastructureheroes.org/topic/ops-1-1-1-a2/), [Permissions](https://www.infrastructureheroes.org/topic/permissions/), [RBAC](https://www.infrastructureheroes.org/topic/rbac/), [Secure Microsoft Active Directory](https://www.infrastructureheroes.org/topic/secure-microsoft-active-directory/)

[Microsoft Active Directory Core Functions: Security, GPOs and Account Management](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/microsoft-active-directory-core-functions-security-gpos-and-account-management/)

[Windows 11 – Disable Microsoft Copilot and AI Features](https://www.infrastructureheroes.org/microsoft-infrastructure/windows-11-disable-microsoft-copilot-and-ai-features/)

### Leave a comment

Comment

Name Email Website

 Save my name, email, and website in this browser for the next time I comment.

## Recent Posts

- [List of different Group Policy Templates (Updated Q2/2026)](https://www.infrastructureheroes.org/microsoft-infrastructure/microsoft-windows/client/windows-10/list-of-different-group-policy-templates-updated/)
- [Windows 11 – Disable Microsoft Copilot and AI Features](https://www.infrastructureheroes.org/microsoft-infrastructure/windows-11-disable-microsoft-copilot-and-ai-features/)
- [AGDLP Explained: The Foundation of Role-Based Access Control in Active Directory](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/agdlp-explained-the-foundation-of-role-based-access-control-in-active-directory/)
- [Microsoft Active Directory Core Functions: Security, GPOs and Account Management](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/microsoft-active-directory-core-functions-security-gpos-and-account-management/)
- [What is Microsoft Active Directory? Structure, Components and Basics](https://www.infrastructureheroes.org/microsoft-infrastructure/active-directory/what-is-microsoft-active-directory-structure-components-and-basics/)

Tags

[Active Directory](https://www.infrastructureheroes.org/topic/active-directory/) [Administrative Templates](https://www.infrastructureheroes.org/topic/administrative-templates/) [APP.2.2.A9](https://www.infrastructureheroes.org/topic/app-2-2-a9/) [Autopilot](https://www.infrastructureheroes.org/topic/autopilot/) [Azure AD](https://www.infrastructureheroes.org/topic/azure-ad/) [Cloud](https://www.infrastructureheroes.org/topic/cloud/) [Deployment](https://www.infrastructureheroes.org/topic/deployment/) [DNS](https://www.infrastructureheroes.org/topic/dns/) [GPO](https://www.infrastructureheroes.org/topic/gpo/) [Group Policy](https://www.infrastructureheroes.org/topic/group-policy/) [Intune](https://www.infrastructureheroes.org/topic/intune/) [IT Baseline Protection](https://www.infrastructureheroes.org/topic/it-baseline-protection/) [LAPS](https://www.infrastructureheroes.org/topic/laps/) [LifeCycle](https://www.infrastructureheroes.org/topic/lifecycle/) [Local Administrator Password Solution](https://www.infrastructureheroes.org/topic/local-administrator-password-solution/) [MDM](https://www.infrastructureheroes.org/topic/mdm/) [MDT](https://www.infrastructureheroes.org/topic/mdt/) [Microsoft](https://www.infrastructureheroes.org/topic/microsoft/) [Microsoft 365](https://www.infrastructureheroes.org/topic/microsoft-365/) [Microsoft Intune](https://www.infrastructureheroes.org/topic/microsoft-intune/) [Office](https://www.infrastructureheroes.org/topic/office/) [Office365](https://www.infrastructureheroes.org/topic/office365/) [Office 2016](https://www.infrastructureheroes.org/topic/office-2016/) [Office 2019](https://www.infrastructureheroes.org/topic/office-2019/) [PowerShell](https://www.infrastructureheroes.org/topic/powershell/) [Privacy](https://www.infrastructureheroes.org/topic/privacy/) [Product LifeCylce](https://www.infrastructureheroes.org/topic/product-lifecylce/) [SCCM](https://www.infrastructureheroes.org/topic/sccm/) [Security](https://www.infrastructureheroes.org/topic/security/) [SMO](https://www.infrastructureheroes.org/topic/smo/) [software distribution](https://www.infrastructureheroes.org/topic/software-distribution/) [Windows](https://www.infrastructureheroes.org/topic/windows/) [Windows10](https://www.infrastructureheroes.org/topic/windows10/) [Windows 10](https://www.infrastructureheroes.org/topic/windows-10/) [Windows 10 Enterprise](https://www.infrastructureheroes.org/topic/windows-10-enterprise/) [Windows 10 Professional](https://www.infrastructureheroes.org/topic/windows-10-professional/) [Windows 11](https://www.infrastructureheroes.org/topic/windows-11/) [Windows as a Service](https://www.infrastructureheroes.org/topic/windows-as-a-service/) [Windows Deployment Service](https://www.infrastructureheroes.org/topic/windows-deployment-service/) [Windows Server 2008R2](https://www.infrastructureheroes.org/topic/windows-server-2008r2/) [Windows Server 2012](https://www.infrastructureheroes.org/topic/windows-server-2012/) [Windows Server 2012R2](https://www.infrastructureheroes.org/topic/windows-server-2012r2/) [Windows Server 2016](https://www.infrastructureheroes.org/topic/windows-server-2016/) [Windows Server 2019](https://www.infrastructureheroes.org/topic/windows-server-2019/) [Windows Server 2022](https://www.infrastructureheroes.org/topic/windows-server-2022/)

- [Privacy Policy](https://www.infrastructureheroes.org/privacy-policy/)
- [Imprint](https://www.infrastructureheroes.org/imprint/)

© 2026 InfrastructureHeroes.org • Built with [GeneratePress](https://generatepress.com)