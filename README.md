# DSK403-PUBLIC — Lab scripts

Script eseguibili per i lab del corso **DSK403 (CKS Exam Prep)** — Kubernetes v1.34.

Questa repository è **pubblica**: lo studente può clonarla direttamente sulla VM del lab e usare gli script senza alcuna autenticazione.

> Domande, scenari e spiegazioni vivono nel repo del corso (`DSK403`, branch `1.34`).
> Qui dentro ci sono solo gli **artefatti eseguibili**.

## Struttura

```
DSK403-PUBLIC/
├── README.md
├── Q01/
│   ├── break.sh     ← porta il cluster nello stato "rotto" del task
│   ├── fix.sh       ← applica la soluzione di riferimento
│   └── cleanup.sh   ← rimuove tutto quanto creato dal lab
├── Q02/
│   ├── break.sh
│   ├── fix.sh
│   └── cleanup.sh
└── ... fino a Q15
```

## Uso

```bash
git clone https://github.com/desotech-it/DSK403-PUBLIC.git
cd DSK403-PUBLIC/Q01

bash break.sh          # cluster nello stato del task
# … leggi la guida del task e prova a risolvere …
bash fix.sh            # applica la soluzione di riferimento (se ti arrendi)
bash cleanup.sh        # quando hai finito
```

Aggiornare a una versione più recente:

```bash
cd ~/DSK403-PUBLIC && git pull
```

## Prerequisiti

- Cluster Kubernetes **v1.32+** (i lab sono pensati per v1.34, ma 1.32+ va bene).
- `kubectl` configurato come admin.
- `helm` (Q11, Q14, Q15).
- `docker` per i lab che modificano il control plane (Q02, Q08, Q10, Q13) o i nodi (Q05) — su `kind` il control plane / i nodi sono container docker.

## Override del control-plane container

I lab di control-plane (Q02, Q08, Q10, Q13) di default assumono che il container del control plane si chiami `dsk102-lab-08-control-plane` (lab DSK102 lab-08). Se il tuo container ha un nome diverso, esportalo prima:

```bash
export CTL=mio-nome-control-plane
bash fix.sh
```

## Convenzioni

- Gli script sono **idempotenti** dove possibile: rilanciarli non danneggia lo stato.
- `cleanup.sh` rimuove **solo** quello che il lab corrispondente ha creato. Non tocca altri lab.
- `fix.sh` è la soluzione di riferimento: non l'unica possibile (ci sono altre soluzioni equivalenti).

## Indice dei lab

| #  | Lab | Dominio CKS |
|----|-----|-------------|
| Q01 | Default-deny NetworkPolicy + DNS/HTTPS egress | Cluster Setup |
| Q02 | `kube-apiserver --anonymous-auth=false` | Cluster Setup |
| Q03 | RBAC con prefix OIDC | Cluster Hardening |
| Q04 | SA + Pod `automountServiceAccountToken: false` | Cluster Hardening |
| Q05 | Caricamento profilo AppArmor sui nodi | System Hardening |
| Q06 | Seccomp `RuntimeDefault` senza `privileged` | System Hardening |
| Q07 | Pod Security Admission `restricted` | Minimize Microservice Vulnerabilities |
| Q08 | Encryption at Rest + rewrite dei Secret | Minimize Microservice Vulnerabilities |
| Q09 | `NET_BIND_SERVICE` per non-root su porta 80 | Minimize Microservice Vulnerabilities |
| Q10 | `ImagePolicyWebhook` admission | Supply Chain Security |
| Q11 | Kyverno `verifyImages` + Cosign | Supply Chain Security |
| Q12 | Trivy `image` / `config` / `k8s` | Supply Chain Security |
| Q13 | Audit Policy mirata sui Secret | Monitoring, Logging and Runtime Security |
| Q14 | Falco rule custom "shell in container" | Monitoring, Logging and Runtime Security |
| Q15 | RuntimeClass gVisor + Kyverno mutate | Monitoring, Logging and Runtime Security |
