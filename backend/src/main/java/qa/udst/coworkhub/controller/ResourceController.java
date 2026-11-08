
package qa.udst.coworkhub.controller;

import qa.udst.coworkhub.entity.BookableResource;
import qa.udst.coworkhub.entity.MeetingRoom;
import qa.udst.coworkhub.entity.Desk;
import qa.udst.coworkhub.entity.ResourceStatus;
import qa.udst.coworkhub.service.ResourceService;

import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/resources")
@CrossOrigin(origins = "*")
public class ResourceController {

    private final ResourceService resourceService;

    // Constructor injection
    public ResourceController(ResourceService resourceService) {
        this.resourceService = resourceService;
    }

    // Get all resources
    @GetMapping
    public ResponseEntity<List<BookableResource>> getAllResources() {
        return ResponseEntity.ok(resourceService.getAllResources());
    }

    // Get resource by ID
    @GetMapping("/{id}")
    public ResponseEntity<BookableResource> getResourceById(
            @PathVariable Long id) {
        return ResponseEntity.ok(resourceService.getResourceById(id));
    }

    // Create a meeting room
    @PostMapping("/rooms")
    public ResponseEntity<BookableResource> createMeetingRoom(
            @RequestBody MeetingRoom room) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(resourceService.createResource(room));
    }

    // Create a desk
    @PostMapping("/desks")
    public ResponseEntity<BookableResource> createDesk(
            @RequestBody Desk desk) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(resourceService.createResource(desk));
    }

    // Update a meeting room
    @PutMapping("/rooms/{id}")
    public ResponseEntity<BookableResource> updateMeetingRoom(
            @PathVariable Long id,
            @RequestBody MeetingRoom room) {
        return ResponseEntity.ok(
                resourceService.updateResource(id, room));
    }

    // Update a desk
    @PutMapping("/desks/{id}")
    public ResponseEntity<BookableResource> updateDesk(
            @PathVariable Long id,
            @RequestBody Desk desk) {
        return ResponseEntity.ok(
                resourceService.updateResource(id, desk));
    }

    // Delete a resource
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteResource(@PathVariable Long id) {
        resourceService.deleteResource(id);
        return ResponseEntity.noContent().build();
    }

    // Filter resources by status
    @GetMapping("/status/{status}")
    public ResponseEntity<List<BookableResource>> getResourcesByStatus(
            @PathVariable ResourceStatus status) {
        return ResponseEntity.ok(
                resourceService.getResourcesByStatus(status));
    }

    // Search resources by location
    @GetMapping("/search/location")
    public ResponseEntity<List<BookableResource>> searchByLocation(
            @RequestParam String location) {
        return ResponseEntity.ok(
                resourceService.searchByLocation(location));
    }

    // Search resources by name
    @GetMapping("/search/name")
    public ResponseEntity<List<BookableResource>> searchByName(
            @RequestParam String name) {
        return ResponseEntity.ok(
                resourceService.searchByName(name));
    }

    // Find resources by minimum capacity
    @GetMapping("/search/capacity")
    public ResponseEntity<List<BookableResource>> findByMinimumCapacity(
            @RequestParam Integer capacity) {
        return ResponseEntity.ok(
                resourceService.findByMinimumCapacity(capacity));
    }
}
