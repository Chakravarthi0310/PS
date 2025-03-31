package com.paysync.server.services;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.ExecutionException;

import org.springframework.stereotype.Service;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.DocumentReference;
import com.google.cloud.firestore.DocumentSnapshot;
import com.google.cloud.firestore.Firestore;
import com.google.cloud.firestore.WriteResult;
import com.google.firebase.cloud.FirestoreClient;
import com.google.firestore.v1.Document;

@Service
public class FirestoreService {
    private static final String COLLECTION_NAME = "users";
    public String createuser(String userId, String name, String email) throws ExecutionException, InterruptedException{
        Firestore db = FirestoreClient.getFirestore();
        Map<String, Object> user = new HashMap<>();

        user.put("name", name);
        user.put("email", email);
        ApiFuture<WriteResult> future = db.collection(COLLECTION_NAME).document(userId).set(user);
        return future.get().getUpdateTime().toString();
    }

    public Map<String,Object> getUser(String userId) throws ExecutionException, InterruptedException{
        Firestore db = FirestoreClient.getFirestore();

        DocumentReference docRef = db.collection(COLLECTION_NAME).document(userId);

        ApiFuture<DocumentSnapshot> future  = docRef.get();

        DocumentSnapshot document = future.get();

        return document.exists() ? document.getData():null;
    }
    public String updateUser(String userId, String name, String email) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();

        Map<String, Object> updates = new HashMap<>();
        updates.put("name", name);
        updates.put("email", email);

        ApiFuture<WriteResult> future = db.collection(COLLECTION_NAME).document(userId).update(updates);
        return future.get().getUpdateTime().toString(); // Returns update time
    }

    public String deleteUser(String userId) throws ExecutionException, InterruptedException {
        Firestore db = FirestoreClient.getFirestore();
        ApiFuture<WriteResult> future = db.collection(COLLECTION_NAME).document(userId).delete();
        return future.get().getUpdateTime().toString(); // Returns delete timestamp
    }


    
}
