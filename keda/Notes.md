Keda - PDB Testing
- Keda doesn't scale with PDB active
- Keda can be used in the development environment, and pdb should be disabled during this period
- PDB will work efficiently in the production environment to avoid voluntery distruptions of pods.
- also, PDB should be used with priorityClasses to ensure High priorty pods are not evicted and allowing
  those with lower priorty to be evicted

Next steps
- Write helm chart templates for keda, pdb and priorityClasses