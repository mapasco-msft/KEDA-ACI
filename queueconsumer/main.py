from azure.identity import ManagedIdentityCredential
from azure.storage.queue import QueueClient
import os


def main(accountName, queueName):
    accountURL = "https://%s.queue.core.windows.net"%(accountName)
    creds = ManagedIdentityCredential()
    client = QueueClient(account_url=accountURL, queue_name=queueName, 
                credential=creds)
    
    messages = client.receive_messages(messages_per_page=1)

    for message in messages:
        print(message.content)
        client.delete_message(message)
    

main(os.environ["STORAGE_ACCOUNT"], os.environ["QUEUE_NAME"])