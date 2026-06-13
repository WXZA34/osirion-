import requests
import json
import argparse
import sys

# ==============================================================================
# SCRIPT DE PENTESTING : INJECTION FIRESTORE
# Teste les règles de sécurité Firebase depuis l'extérieur de l'application
# ==============================================================================

# Configurations (À REMPLIR PAR LE TESTEUR)
# Trouvez votre Web API Key dans Firebase Console > Paramètres du projet > Général
FIREBASE_WEB_API_KEY = "VOTRE_WEB_API_KEY_ICI" 
PROJECT_ID = "votre-projet-id"

def authenticate_user(email, password):
    """Émule le login d'un utilisateur pour obtenir un Firebase ID Token (JWT)"""
    print(f"[*] Tentative d'authentification pour {email}...")
    auth_url = f"https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key={FIREBASE_WEB_API_KEY}"
    payload = {
        "email": email,
        "password": password,
        "returnSecureToken": True
    }
    
    response = requests.post(auth_url, json=payload)
    data = response.json()
    
    if "error" in data:
        print(f"[!] Erreur d'authentification : {data['error']['message']}")
        sys.exit(1)
        
    print("[+] Authentification réussie ! Token obtenu.")
    return data['idToken'], data['localId']

def test_firestore_read_injection(id_token, target_collection, target_doc):
    """Tente de lire un document Firestore en utilisant le token"""
    print(f"[*] Tentative de lecture de {target_collection}/{target_doc}...")
    firestore_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/{target_collection}/{target_doc}"
    
    headers = {
        "Authorization": f"Bearer {id_token}"
    }
    
    response = requests.get(firestore_url, headers=headers)
    
    if response.status_code == 200:
        print("[!] SUCCÈS (Vulnérabilité potentielle) : Lecture autorisée.")
        print(json.dumps(response.json(), indent=2))
    elif response.status_code == 403:
        print("[+] ÉCHEC (Sécurisé) : Accès refusé par les règles Firestore (403 Forbidden).")
    else:
        print(f"[-] Résultat inattendu : {response.status_code} - {response.text}")

def test_firestore_write_injection(id_token, uid):
    """Tente de modifier son propre XP illégalement (Vérifie la règle !hasAny(['forceXP']))"""
    print(f"[*] Tentative de modification illégale de forceXP pour l'utilisateur {uid}...")
    
    firestore_url = f"https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/users/{uid}?updateMask.fieldPaths=forceXp"
    
    headers = {
        "Authorization": f"Bearer {id_token}",
        "Content-Type": "application/json"
    }
    
    # Tentative d'injection de 999999 XP
    payload = {
        "fields": {
            "forceXp": {
                "integerValue": "999999"
            }
        }
    }
    
    response = requests.patch(firestore_url, headers=headers, json=payload)
    
    if response.status_code == 200:
        print("[!] SUCCÈS (VULNÉRABILITÉ CRITIQUE) : L'injection d'XP a fonctionné !")
    elif response.status_code == 403:
        print("[+] ÉCHEC (Sécurisé) : La règle Firestore a bloqué la modification d'XP (403 Forbidden).")
    else:
        print(f"[-] Résultat inattendu : {response.status_code} - {response.text}")

if __name__ == "__main__":
    print("=== DÉMARRAGE DE L'AUDIT FIRESTORE EXTERNE ===")
    
    # Remplacez par des identifiants de test valides
    TEST_EMAIL = "test_alpha@osirion.com"
    TEST_PASSWORD = "password123"
    
    if FIREBASE_WEB_API_KEY == "VOTRE_WEB_API_KEY_ICI":
        print("[!] Configurez FIREBASE_WEB_API_KEY et PROJECT_ID dans le script avant de lancer.")
        sys.exit(1)
        
    token, uid = authenticate_user(TEST_EMAIL, TEST_PASSWORD)
    
    print("\n--- TEST 1 : Lecture d'un Chat Privé interdit ---")
    # Remplacez par un vrai ID de chat où l'utilisateur n'est PAS participant
    test_firestore_read_injection(token, "private_chats", "ID_DU_CHAT_CIBLE")
    
    print("\n--- TEST 2 : Injection Anti-Triche sur forceXP ---")
    test_firestore_write_injection(token, uid)
    
    print("\n=== FIN DE L'AUDIT ===")
