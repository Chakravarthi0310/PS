package com.paysync.server.service;

import com.google.cloud.firestore.CollectionReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.QuerySnapshot;
import com.google.firebase.cloud.FirestoreClient;
import org.springframework.stereotype.Service;

import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

@Service
public class SyncService {

    public void syncToFirestore(Map<String, Object> changes) {
        Firestore db = FirestoreClient.getFirestore();
        
        try {
            // Process each change
            for (Map.Entry<String, Object> entry : changes.entrySet()) {
                String collection = entry.getKey();
                Map<String, Object> documents = (Map<String, Object>) entry.getValue();
                
                for (Map.Entry<String, Object> doc : documents.entrySet()) {
                    String documentId = doc.getKey();
                    Map<String, Object> data = (Map<String, Object>) doc.getValue();
                    
                    // Add sync timestamp
                    data.put("lastSynced", System.currentTimeMillis());
                    
                    // Update or create document in Firestore
                    db.collection(collection).document(documentId)
                        .set(data)
                        .get();
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to sync with Firestore", e);
        }
    }

    public Map<String, Object> getChangesFromFirestore(String lastSyncTimestamp) {
        Firestore db = FirestoreClient.getFirestore();
        Map<String, Object> changes = new HashMap<>();
        long lastSync = Long.parseLong(lastSyncTimestamp);

        try {
            // Get changes for each collection
            String[] collections = {"users", "events", "transactions", "savings_goals"};
            for (String collection : collections) {
                Map<String, Object> collectionChanges = new HashMap<>();
                
                db.collection(collection)
                    .whereGreaterThan("lastSynced", lastSync)
                    .get()
                    .get()
                    .getDocuments()
                    .forEach(doc -> collectionChanges.put(doc.getId(), doc.getData()));
                
                if (!collectionChanges.isEmpty()) {
                    changes.put(collection, collectionChanges);
                }
            }
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to fetch changes from Firestore", e);
        }

        return changes;
    }

    public Map<String, Object> getUserDataFromFirestore(String userId) {
        Firestore db = FirestoreClient.getFirestore();
        Map<String, Object> allData = new HashMap<>();
        
        try {
            // Get user data
            DocumentSnapshot userDoc = db.collection("users").document(userId).get().get();
            
            if (userDoc.exists()) {
                Map<String, Object> userData = userDoc.getData();
                if (userData != null) {
                    userData.remove("lastSynced"); // Remove sync timestamp
                    allData.put("users", Collections.singletonMap(userId, userData));
                }
                
                // Get user's events
                CollectionReference eventsRef = db.collection("events");
                QuerySnapshot eventDocs = eventsRef.whereArrayContains("members", userId).get().get();
                Map<String, Object> events = new HashMap<>();
                eventDocs.forEach(doc -> {
                    Map<String, Object> eventData = doc.getData();
                    eventData.remove("lastSynced"); // Remove sync timestamp
                    events.put(doc.getId(), eventData);
                });
                if (!events.isEmpty()) {
                    allData.put("events", events);
                }

                // Get user's transactions
                CollectionReference transactionsRef = db.collection("transactions");
                QuerySnapshot transactionDocs = transactionsRef
                    .whereEqualTo("userId", userId)
                    .get()
                    .get();
                Map<String, Object> transactions = new HashMap<>();
                transactionDocs.forEach(doc -> {
                    Map<String, Object> transactionData = doc.getData();
                    transactionData.remove("lastSynced"); // Remove sync timestamp
                    transactions.put(doc.getId(), transactionData);
                });
                if (!transactions.isEmpty()) {
                    allData.put("transactions", transactions);
                }
            }
            
            return allData;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Failed to fetch user data from Firestore", e);
        }
    }
}