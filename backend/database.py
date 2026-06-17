import os
import firebase_admin
from firebase_admin import credentials, firestore
import google.auth.credentials
from google.auth.credentials import AnonymousCredentials

# Standard Google Cloud Emulator Environment Variables
os.environ["FIREBASE_AUTH_EMULATOR_HOST"] = "127.0.0.1:9099"
os.environ["FIRESTORE_EMULATOR_HOST"] = "127.0.0.1:8080"
os.environ["FIREBASE_STORAGE_EMULATOR_HOST"] = "127.0.0.1:9199"
os.environ["STORAGE_EMULATOR_HOST"] = "http://127.0.0.1:9199" # Standard GCS variable
os.environ["GCLOUD_PROJECT"] = "demo-onlygigz"

print(f"--- Firebase Initialization ---")
print(f"Auth Emulator: {os.getenv('FIREBASE_AUTH_EMULATOR_HOST')}")
print(f"Firestore Emulator: {os.getenv('FIRESTORE_EMULATOR_HOST')}")
print(f"Storage Emulator: {os.getenv('STORAGE_EMULATOR_HOST')}")
print(f"Project ID: {os.getenv('GCLOUD_PROJECT')}")

# Initialize Firebase Admin for Emulator
if not firebase_admin._apps:
    # Use a dummy certificate for the emulator
    cred = credentials.Certificate({
        "type": "service_account",
        "project_id": "demo-onlygigz",
        "private_key_id": "dummy-key-id",
        "private_key": "-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEAoq//UsKS9Gex2oRn/aOzdEe821k8R5HFzPDQ8PtCCaARDXex\nYv+bp4WY1+tYppEQ7HY1DN4+mHJe3SIS7U1Wjt/C139oJS34C+7S9yZuFQGHcGs7\nXqC6FQCmQtfe+Vnz5Px0re6bQ/benBvd1gpWQra/4O78x9AVMKxPIonz1xlckbRe\nNRYO06d2yT7VEG14jmq/F0QaGr13C5i6P+csgmNZbhbn+JeQ9WjEoJTY8i6i+L1i\nE57b1U+HaOVC39rUXfaDwP6nCKwzegTpfqcdORctj/EmdWFK3ryqDjO3CUtctQ2p\nCvdyrbL+k8HhdyyoERc90tnyaLzVl8Fi5VKqVwIDAQABAoIBABChIt0nzHO1IcXv\nYN3ZXN+W8aQORA4gxXJEb2cil8Z6GSQiRvySmiuOiWgQw3gLPgqdrqCJGybkEfRS\nplKhZCaokrcKa+/Y+hDmMaRXxkrZZCnGnEP48+xvq48Ll9wvKLIQaDDbQf25f1m/\ns3ZMijK5kXWBmE8oYvIdut0R8t3arPiux08YN4TjTgXw17fmm1irWy9TQc58CGMM\ndqda66yXZ4eoI2ePaHQZvdmtaKC4GmxDHUFqjuBDvLIMmRtSSDOEmJuC7TjMVVdR\ndgAHyNS6jNv40mJQ0+2Unl1eKK+QKq06Kn7fTt+VAFwrmECzg22vZZCRST9eohxS\nOUM8xFkCgYEA28ejkiMQWpfnP+pqunaGXjCMijbe4oBM2vLUn8VM6Mqr0KDwHU5D\nvACR2h129y4HuwBtTJ5TDn2xPqX9kIC8wrcXHkYaqeOOl5RGvRS5oJ+trqObCAyd\n8JlG0gsKIy5srJr1J+/rHS8jHR4wmT4d7yiz1C90UbWhnfmyzApm0nsCgYEAvX+r\n1Zc37s/+AsZC+kgI1ku6NsLgdFYUeqfiuYkGmhn2vJ48klk0dQSnJk1Wu9Bt3YX+\nBGTovRHQnUzjERvYRN38ZYOfD0610AkZV2y5v9ZjW+YLDTUWukoGcz2mJ8GdmWMr\nDIyq+QTkLzgyTXJtOOGN+Wc2772esg8VSvF3ftUCgYEAyR4TbPNxT7WaBD87k45K\nv36l3QUBSTwnGGUGdX5TNuPf/naHxAmOqkfLMFGuP9t7b4CghHCNiME0pSO4ubdV\nBMoO+cElPTnjjoo9gWGpzHbStPE6OU9yaG2bBTLc//zHrdvPY9CE0pwEAe1Sg6j4\nM5aHmTAjvXH8h1esalNKbGkCgYBp1jOnwKSJqfspm4fu92qQHY1sZl0sPKOFedzk\nWQap7NRktlAIQPBOZwHgH5PQo/GoptyfoahnaNrF8BpmBNI+bGk6XU/qIcDj5yET\nNfNslJW7zvjfMIZ4Fz4RAR6a18Vo1P1HLg2TtUqooM9feAhOm5NK9320WoiW1FvF\nFqXx3QKBgD/jDQmBdB5DAzxtEG+5mbiSJ8Z9Gyjq2tg33IDkD3WJ3WQIy7NS9iN8\nPev/rtFqXbTGD/UHb3+C8riGXvLWj48Yeu3BwJv3V7lijBKI/onaIsiFeJceNNFY\nDF+8i6HTGHXYHNRDzOUWglTl6fwI6nD2XC0QYg+fzc1qw6iqKCh/\n-----END RSA PRIVATE KEY-----\n",
        "client_email": "dummy@demo-onlygigz.iam.gserviceaccount.com",
        "client_id": "dummy-client-id",
        "auth_uri": "https://accounts.google.com/o/oauth2/auth",
        "token_uri": "https://oauth2.googleapis.com/token",
        "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
        "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/dummy%40demo-onlygigz.iam.gserviceaccount.com"
    })
    
    firebase_admin.initialize_app(cred, {
        'projectId': 'demo-onlygigz',
        'storageBucket': 'demo-onlygigz.appspot.com'
    })

db = firestore.client()
