package com.paysync.server.controller;

import com.paysync.server.service.SyncService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/sync")
public class SyncController {

    @Autowired
    private SyncService syncService;

    @PostMapping("/changes")
    public ResponseEntity<?> syncChanges(@RequestBody Map<String, Object> changes) {
        syncService.syncToFirestore(changes);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/changes")
    public ResponseEntity<?> getChanges(@RequestParam String lastSyncTimestamp) {
        Map<String, Object> changes = syncService.getChangesFromFirestore(lastSyncTimestamp);
        return ResponseEntity.ok(changes);
    }

    @GetMapping("/users/{userId}")  // Changed from /user/{userId} to /users/{userId}
    public ResponseEntity<?> getUserData(@PathVariable String userId) {
        Map<String, Object> userData = syncService.getUserDataFromFirestore(userId);
        return ResponseEntity.ok(userData);
    }
}