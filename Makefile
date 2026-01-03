.PHONY: help install check deploy deploy-registry deploy-k8s deploy-app deploy-haproxy clean

help:
	@echo "Available targets:"
	@echo "  install          - Install Ansible collections"
	@echo "  check            - Run playbook in check mode"
	@echo "  deploy           - Full deployment"
	@echo "  deploy-registry  - Deploy Docker registry only"
	@echo "  deploy-k8s       - Deploy Kubernetes only"
	@echo "  deploy-app       - Deploy React app only"
	@echo "  deploy-haproxy   - Deploy HAProxy only"
	@echo "  clean            - Clean cache and facts"

install:
	ansible-galaxy collection install -r requirements.yml
	sudo apt install -y python3-kubernetes python3-docker || pip3 install kubernetes docker --break-system-packages

check:
	ansible-playbook playbooks/site.yml --check --diff

deploy:
	ansible-playbook playbooks/site.yml

deploy-registry:
	ansible-playbook playbooks/deploy-registry.yml

deploy-k8s:
	ansible-playbook playbooks/deploy-kubernetes.yml

deploy-app:
	ansible-playbook playbooks/deploy-app.yml

deploy-haproxy:
	ansible-playbook playbooks/deploy-haproxy.yml

clean:
	rm -rf /tmp/ansible_facts
	rm -rf /tmp/ansible-ssh-*
