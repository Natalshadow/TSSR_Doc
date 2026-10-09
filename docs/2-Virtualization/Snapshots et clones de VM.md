• [Snapshots] (Définition, avantages, limites). 
• [Clone] de [[VM]] (types de clones, cas d'utilisation).

## Key Differences

| **Feature**            | **[VM](VM.md) Snapshot**                                             | **[VM](VM.md) Clone**                                                        |
| ---------------------- | ----------------------------------------------------------- | ------------------------------------------------------------------- |
| **Primary Goal**       | Short-term safety net (rollback point)                      | Long-term template or standalone copy                               |
| **[VM](VM.md) Power State**     | Done **Live** ([VM](VM.md) runs continuously while taken)            | Best done **Shut Down** (or cold) to avoid state inconsistency      |
| **Storage Usage**      | Very small initially; grows as delta/changes accumulate     | **Doubles storage space** immediately (exact full duplicate)        |
| **Dependency**         | Dependent on the parent base disk (deleting base breaks it) | **Fully independent** (has its own new MAC address, UUID, and disk) |
| **Performance Impact** | Degrades [VM](VM.md) performance if kept long-term                   | None (operates as a standard standalone [VM](VM.md))                         |
| **Use Case**           | Before applying updates, patches, or risky commands         | Creating templates, dev environments, or staging servers            |

## Quick Summary

- **Snapshot = A "Save State" in a video game.** It records the exact disk state and RAM at a specific moment. It is **not a backup**—it relies on the original disk file and should be deleted once your changes or updates are confirmed working.
    
- **Clone = A complete copy-paste of the entire [VM](VM.md).** It creates a whole new virtual machine with no links to the original. You can move it to another host, delete the source [VM](VM.md), or spin it up alongside the original without IP or MAC address collisions.
- [Linked Clone] = a simlink copy of the original, this time it doesn't duplicate the disk and relies on the original one. However the deletion of the original renders all the Linked Clones useless.



## Notes to self
Neither of them sound like actual archival backups or redundancies. One sounds short term roll-back, the other seems meant to be used for transfers and quick deploy.

Screenshots de confirmation:
![[../9-Labs and TP/attachments/Pasted image 20261001095251.png]]
![[../9-Labs and TP/attachments/Pasted image 20261001095318.png]]