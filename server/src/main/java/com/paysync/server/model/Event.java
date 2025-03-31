package com.paysync.server.model;

import com.google.cloud.Timestamp;

import java.util.ArrayList;
import java.util.List;

public class Event {
    private String eventId;
    private String nameOfEvent;
    private String createdBy;
    private List<String> transactions;
    private Double onlineAmountOfEvent;
    private Double offlineAmountOfEvent;
    private List<String> members;
    private String currency;
    private Double budget;
    private Timestamp createdAt;
    private Timestamp updatedAt;

    // Default constructor
    /**
     * Default constructor required for JPA/Hibernate entity instantiation and serialization.
     * All fields will be initialized through setters after object creation.
     */
    public Event() {
        // Initialize collections to prevent null pointer exceptions
        this.transactions = new ArrayList<>();
        this.members = new ArrayList<>();
    }

    // Getters and Setters
    public String getEventId() { return eventId; }
    public void setEventId(String eventId) { this.eventId = eventId; }

    public String getNameOfEvent() { return nameOfEvent; }
    public void setNameOfEvent(String nameOfEvent) { this.nameOfEvent = nameOfEvent; }

    public String getCreatedBy() { return createdBy; }
    public void setCreatedBy(String createdBy) { this.createdBy = createdBy; }

    public List<String> getTransactions() { return transactions; }
    public void setTransactions(List<String> transactions) { this.transactions = transactions; }

    public Double getOnlineAmountOfEvent() { return onlineAmountOfEvent; }
    public void setOnlineAmountOfEvent(Double onlineAmountOfEvent) { this.onlineAmountOfEvent = onlineAmountOfEvent; }

    public Double getOfflineAmountOfEvent() { return offlineAmountOfEvent; }
    public void setOfflineAmountOfEvent(Double offlineAmountOfEvent) { this.offlineAmountOfEvent = offlineAmountOfEvent; }

    public List<String> getMembers() { return members; }
    public void setMembers(List<String> members) { this.members = members; }

    public String getCurrency() { return currency; }
    public void setCurrency(String currency) { this.currency = currency; }

    public Double getBudget() { return budget; }
    public void setBudget(Double budget) { this.budget = budget; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }
}