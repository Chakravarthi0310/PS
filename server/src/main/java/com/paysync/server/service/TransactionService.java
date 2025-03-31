package com.paysync.server.service;

import com.google.api.core.ApiFuture;
import com.google.cloud.firestore.*;
import com.google.firebase.cloud.FirestoreClient;
import com.paysync.server.model.Transaction;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutionException;

@Service
public class TransactionService {

    private static final String COLLECTION_NAME = "transactions";

    private Firestore getFirestore() {
        return FirestoreClient.getFirestore();
    }

    public Transaction createTransaction(Transaction transaction) {
        try {
            DocumentReference docRef = getFirestore().collection(COLLECTION_NAME).document();
            transaction.setTransactionId(docRef.getId());
            docRef.set(transaction).get();
            return transaction;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error creating transaction", e);
        }
    }

    public Transaction getTransaction(String transactionId) {
        try {
            DocumentReference docRef = getFirestore().collection(COLLECTION_NAME).document(transactionId);
            ApiFuture<DocumentSnapshot> future = docRef.get();
            DocumentSnapshot document = future.get();
            
            if (document.exists()) {
                return document.toObject(Transaction.class);
            } else {
                throw new RuntimeException("Transaction not found");
            }
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error fetching transaction", e);
        }
    }

    public List<Transaction> getUserTransactions(String userId) {
        try {
            Query query = getFirestore().collection(COLLECTION_NAME).whereEqualTo("userId", userId);
            return executeQuery(query);
        } catch (Exception e) {
            throw new RuntimeException("Error fetching user transactions", e);
        }
    }

    public List<Transaction> getEventTransactions(String eventId) {
        try {
            Query query = getFirestore().collection(COLLECTION_NAME).whereEqualTo("eventId", eventId);
            return executeQuery(query);
        } catch (Exception e) {
            throw new RuntimeException("Error fetching event transactions", e);
        }
    }

    public Transaction updateTransaction(String transactionId, Transaction transaction) {
        try {
            DocumentReference docRef = getFirestore().collection(COLLECTION_NAME).document(transactionId);
            transaction.setTransactionId(transactionId);
            docRef.set(transaction).get();
            return transaction;
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error updating transaction", e);
        }
    }

    public void deleteTransaction(String transactionId) {
        try {
            DocumentReference docRef = getFirestore().collection(COLLECTION_NAME).document(transactionId);
            docRef.delete().get();
        } catch (InterruptedException | ExecutionException e) {
            throw new RuntimeException("Error deleting transaction", e);
        }
    }

    private List<Transaction> executeQuery(Query query) throws ExecutionException, InterruptedException {
        ApiFuture<QuerySnapshot> future = query.get();
        List<Transaction> transactions = new ArrayList<>();
        QuerySnapshot querySnapshot = future.get();
        for (DocumentSnapshot document : querySnapshot.getDocuments()) {
            transactions.add(document.toObject(Transaction.class));
        }
        return transactions;
    }
}