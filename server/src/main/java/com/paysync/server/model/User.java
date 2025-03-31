package com.paysync.server.model;

import com.google.cloud.Timestamp;
import java.util.List;
import java.util.Map;

public class User {
    private String userId;
    private String username;
    private String phoneNumber;
    private String profileImageUrl;
    private String defaultCurrency;
    private Double onlineAmount;
    private Double offlineAmount;
    private List<String> events;
    private String defaultEventId;
    private Timestamp createdAt;
    private Timestamp updatedAt;
    private Map<String, Boolean> preferences;

    // Default constructor
    /**
     * Default constructor required for JPA/Hibernate and JSON serialization.
     * All fields will be initialized through setters after construction.
     */
    public User() {
        // Initialize default values for primitive fields
        this.onlineAmount = 0.0;
        this.offlineAmount = 0.0;
        this.defaultCurrency = "USD";
    }

    // Getters and Setters
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getPhoneNumber() { return phoneNumber; }
    public void setPhoneNumber(String phoneNumber) { this.phoneNumber = phoneNumber; }


    public String getProfileImageUrl() { return profileImageUrl; }
    public void setProfileImageUrl(String profileImageUrl) { this.profileImageUrl = profileImageUrl; }

    public String getDefaultCurrency() { return defaultCurrency; }
    public void setDefaultCurrency(String defaultCurrency) { this.defaultCurrency = defaultCurrency; }

    public Double getOnlineAmount() { return onlineAmount; }
    public void setOnlineAmount(Double onlineAmount) { this.onlineAmount = onlineAmount; }

    public Double getOfflineAmount() { return offlineAmount; }
    public void setOfflineAmount(Double offlineAmount) { this.offlineAmount = offlineAmount; }

    public List<String> getEvents() { return events; }
    public void setEvents(List<String> events) { this.events = events; }

    public String getDefaultEventId() { return defaultEventId; }
    public void setDefaultEventId(String defaultEventId) { this.defaultEventId = defaultEventId; }

    public Timestamp getCreatedAt() { return createdAt; }
    public void setCreatedAt(Timestamp createdAt) { this.createdAt = createdAt; }

    public Timestamp getUpdatedAt() { return updatedAt; }
    public void setUpdatedAt(Timestamp updatedAt) { this.updatedAt = updatedAt; }

    public Map<String, Boolean> getPreferences() { return preferences; }
    public void setPreferences(Map<String, Boolean> preferences) { this.preferences = preferences; }
}