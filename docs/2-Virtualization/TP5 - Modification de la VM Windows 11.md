---
tags:
  - VM
  - VMWare
  - Virtualization
---

## Pre-Flight Checklist

- [x] VM completely shut down before editing CPU and Disk sizes.
    
- [x] Host machine has sufficient available physical RAM ($\ge 8\text{ GB}$) and free disk space ($\ge 15\text{ GB}$).
    
- [x] VMware Workstation snapshot created prior to storage modifications.


### Mission 1 — Initial Resource Baseline

1. Open **VMware Workstation** $\rightarrow$ Select `CLI-WIN-MEN-01` $\rightarrow$ **Edit virtual machine settings**.
    
2. Note baseline specs: **2 vCPU**, **4 GB RAM**, **64 GB System Disk (SCSI)**.

### Mission 2 & 3 — vRAM & vCPU Allocation

1. Shut down Windows cleanly if required: `Start` $\rightarrow$ `Power` $\rightarrow$ `Shut Down`.
    
2. In VMware Workstation: **VM Settings** $\rightarrow$ **Hardware**:
    
    - **Memory:** Adjust slider/input to **`6144 MB`** (6 GB).
        
    - **Processors:** Set _Number of processors_ / _cores_ to total **`4 vCPU`**.
        
3. Click **OK** and power on `CLI-WIN-MEN-01`.
    
4. **Verification:** Open **Task Manager** $\rightarrow$ **Performance**:
    
    - **CPU:** Verify `4 Virtual Processors` displayed.
        
    - **Memory:** Verify `6.0 GB` total RAM displayed.
        

### Mission 4 — Expand System Disk (C:)

#### Part A: VMware Disk Expansion

1. Power off `CLI-WIN-MEN-01`.

2. Disable and remove snapshots to enable hard disk expansion

3. **VM Settings** $\rightarrow$ **Hard Disk (SCSI)** $\rightarrow$ **Utilities** dropdown $\rightarrow$ **Expand...**
    
4. Enter Maximum disk size: **`65 GB`** $\rightarrow$ Click **Expand** $\rightarrow$ Click **OK**.
    

#### Part B: Extend Volume in Windows GUI

1. Power on `CLI-WIN-MEN-01`.
    
2. Right-click Start button $\rightarrow$ **Disk Management** (`diskmgmt.msc`).
    
3. Locate **Disk 0**: Verify **`1.00 GB Unallocated`** space appears on the right.
    
4. _Conditional Execution:_
    
    - **Adjacent Space:** Right-click **`(C:)`** $\rightarrow$ **Extend Volume...** $\rightarrow$ Click **Next** $\rightarrow$ Accept maximum space $\rightarrow$ **Finish**.
        
    - **Non-Adjacent Space (WinRE Block):** Document blockers in inventory notes if recovery partition prevents immediate GUI extension.
        
5. **Verification:** Open **File Explorer** (`Win + E`) $\rightarrow$ **This PC** $\rightarrow$ Verify `C:` total capacity reflects extended volume size.
    

### Mission 5 & 6 — Dedicated Data Disk (DATA - 2 GB)

#### Part A: Add Fixed Virtual Disk in VMware

1. **VM Settings** $\rightarrow$ **Add...** $\rightarrow$ **Hard Disk** $\rightarrow$ Click **Next**.
    
2. Select Disk Type: **SCSI** (Recommended).
    
3. Select: **Create a new virtual disk**.
    
4. Set Capacity: **`2 GB`**.
    
5. Check option: **Allocate all disk space now** (Fixed/Thick Provisioned) $\rightarrow$ Save as single file.
    
6. Complete wizard and confirm **Hard Disk 2 (2 GB)** appears in VM hardware list.
    

#### Part B: Initialize and Format in Windows

1. Power on VM $\rightarrow$ Open **Disk Management** (`diskmgmt.msc`).
    
2. Pop-up prompt: **Initialize Disk** for **Disk 1** $\rightarrow$ Select **GPT (GUID Partition Table)** $\rightarrow$ Click **OK**.
    
3. Right-click the **2 GB Unallocated** area on Disk 1 $\rightarrow$ **New Simple Volume...**
    
4. Set parameters:
    
    - **Volume Size:** Max size (entire 2 GB).
        
    - **Drive Letter:** Assign next available letter (e.g., `D:` or `E:`).
        
    - **File System:** `NTFS`.
        
    - **Volume Label:** `DATA`.
        
5. Complete wizard and format volume.
    
6. **Verification:** Open **File Explorer** $\rightarrow$ Confirm **`DATA`** drive appears under **This PC**.


# Fiche de configuration — poste Windows

| Élément              | Ancienne valeur    | Nouvelle valeur |
| -------------------- | ------------------ | --------------- |
| Nom de la [VM](VM.md)         | `CLI-WIN-MEN-01`   | =               |
| Rôle                 | Poste client       | =               |
| Système              | Windows 11         | =               |
| Édition              | Professionnel      | =               |
| Version              | 26H2               | =               |
| vCPU                 | 2                  | 4               |
| RAM                  | 4 Go               | 6               |
| Disque virtuel       | 64 Go              | 65 + 2          |
| Réseau logique       | `LAB-TSSR`         | =               |
| Réseau VMware        | `VMnet8`           | =               |
| Mode réseau          | NAT                | =               |
| Compte utilisé       | Compte local       | =               |
| Date d'installation  | 2026-09-30 14 h 18 | =               |
| État Windows Update  | À jour             | =               |
| État périphériques   | OK                 | =               |
| Accès Internet testé | Oui                | =               |
| Remarques            | RAS                | =               |
|                      |                    |                 |
|                      |                    |                 |
[VM](VM.md) Ware config
![[../2-Virtualization/attachments/Pasted image 20261001155321.png]]

Windows configuration

![[../2-Virtualization/attachments/Pasted image 20261001155253.png]]
The current order of the partitions on the C disk does not allow expanding its size. I think we would need to potentially pause/stop the recovery system briefly and diskpart the expansion of the partition, then turn recovery back on. 
On Linux it would be a simple case of systemctl stop/start but I'm not familiar with the commands for Windows in that case.


# Bonus - Connect shared drive

Bonus - Connect shared drive
![Shared Drive Config](../2-Virtualization/attachments/Pasted%20image%2020261001154218.png)
![Shared Drive Drive Letter](../2-Virtualization/attachments/Pasted%20image%2020261001154136.png)


Test:
![[../2-Virtualization/attachments/Pasted image 20261001164109.png]]


[[VM]]
