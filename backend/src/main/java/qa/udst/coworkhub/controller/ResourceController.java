
package qa.udst.coworkhub.controller;

import qa.udst.coworkhub.entity.BookableResource;
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

    // Create a new resource
    @PostMapping
    public ResponseEntity<BookableResource> createResource(
            @RequestBody BookableResource resource) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(resourceService.createResource(resource));
    }

    // Update a resource
    @PutMapping("/{id}")
    public ResponseEntity<BookableResource> updateResource(
            @PathVariable Long id,
            @RequestBody BookableResource resource) {
        return ResponseEntity.ok(
                resourceService.updateResource(id, resource));
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
