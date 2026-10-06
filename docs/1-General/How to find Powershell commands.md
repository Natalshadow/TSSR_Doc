## 1. PowerShell was designed for discovery: The "Verb-Noun" rule

Unlike Linux, where command names are arbitrary historical abbreviations (`ls`, `grep`, `awk`, `tar`, `chmod`), PowerShell follows a strict **Verb-Noun** naming convention:

$$\text{Command} = \text{Verb} - \text{Noun}$$

- **Verbs** tell PowerShell _what to do_ (`Get`, `Set`, `New`, `Remove`, `Install`, `Restart`, `Test`).
    
- **Nouns** tell PowerShell _what object to affect_ (`Service`, `NetIPAddress`, `ADUser`, `WindowsFeature`).
    

Because of this rigid rule, you only need **three discovery commands** to find almost anything:

### A. Find any command (`Get-Command`)

Want to do something with DNS, but don't know the command? Search by Noun:

PowerShell

```
Get-Command -Noun *Dns*
```

Want to see everything you can _install_? Search by Verb:

PowerShell

```
Get-Command -Verb Install
```

### B. Learn how to use a command (`Get-Help`)

Once you find a command, ask PowerShell how to use it—especially with the `-Examples` flag:

PowerShell

```
Get-Help Install-ADDSForest -Examples
```

### C. Discover what an object can do (`Get-Member`)

In Linux, text streams through pipes. In PowerShell, **objects** pass through pipes. If you get an object and want to see what properties or methods it has, pipe it to `Get-Member`:

PowerShell

```
Get-Service DNS | Get-Member
```

## 2. The Mental Model Shift: From Memorizing to Querying

You don't need to memorize `Install-ADDSForest`. You just need to train your brain on a 3-step reasoning framework whenever you face a new task:

```
1. What am I trying to affect?  --> "Active Directory Domain Services" / "ADDS"
2. What action am I performing? --> "Install"
3. Query PowerShell:            --> Get-Command -Verb Install -Noun *AD*
```

## 3. Practical Cheatsheet: The "Linux to PowerShell" Translation Map

Since you already have Linux experience, leverage what you already know. PowerShell even includes built-in aliases so Linux commands work out of the box (`ls` $\rightarrow$ `Get-ChildItem`, `cat` $\rightarrow$ `Get-Content`, `clear` $\rightarrow$ `Clear-Host`).

|**Task**|**Linux Mental Model**|**PowerShell Discovery Strategy**|**The Actual PowerShell Cmdlet**|
|---|---|---|---|
|**Check Network IP**|`ipconfig` / `ip addr`|`Get-Command -Noun *IPAddress*`|`Get-NetIPAddress`|
|**Test Connectivity**|`ping` / `nc -zv`|`Get-Command -Verb Test -Noun *Connection*`|`Test-NetConnection`|
|**Manage Services**|`systemctl restart <srv>`|`Get-Command -Noun *Service*`|`Restart-Service`|
|**DNS Lookup**|`dig <domain>`|`Get-Command -Noun *Dns*`|`Resolve-DnsName`|
|**Install Packages**|`apt install` / `dnf`|`Get-Command -Verb Install -Noun *Feature*`|`Install-WindowsFeature`|

## 4. How to Bridge the "I Don't Know What's Possible" Gap

1. **Use Auto-Completion Aggressively:** Type `Get-AD` and press `Tab` or `Ctrl + Space`. PowerShell will display a interactive list of every Active Directory command available on the system.
    
2. **Read Scripting Examples Over Documentation:** When reading Microsoft docs, scroll straight to the **EXAMPLES** section at the bottom.
    
3. **Use AI as a Query Translator:** Ask questions framed around your intent: _"I know how to do X in Linux or via Windows GUI, what is the PowerShell equivalent?"_