
package qa.udst.coworkhub.service;

import qa.udst.coworkhub.entity.BookableResource;
import qa.udst.coworkhub.entity.ResourceStatus;
import qa.udst.coworkhub.repository.ResourceRepository;

import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class ResourceService {

    private final ResourceRepository resourceRepository;

    // Constructor injection
    public ResourceService(ResourceRepository resourceRepository) {
        this.resourceRepository = resourceRepository;
    }

    // Get all resources
    public List<BookableResource> getAllResources() {
        return resourceRepository.findAll();
    }

    // Get resource by ID
    public BookableResource getResourceById(Long id) {
        return resourceRepository.findById(id)
                .orElseThrow(() ->
                        new RuntimeException("Resource not found with ID: " + id));
    }

    // Create a new resource
    public BookableResource createResource(BookableResource resource) {
        return resourceRepository.save(resource);
    }

    // Update an existing resource
    public BookableResource updateResource(Long id, BookableResource updatedResource) {

        BookableResource existingResource = getResourceById(id);

        existingResource.setName(updatedResource.getName());
        existingResource.setLocation(updatedResource.getLocation());
        existingResource.setCapacity(updatedResource.getCapacity());
        existingResource.setHourlyRate(updatedResource.getHourlyRate());
        existingResource.setStatus(updatedResource.getStatus());

        return resourceRepository.save(existingResource);
    }

    // Delete resource
    public void deleteResource(Long id) {
        BookableResource resource = getResourceById(id);
        resourceRepository.delete(resource);
    }

    // Filter resources by status
    public List<BookableResource> getResourcesByStatus(ResourceStatus status) {
        return resourceRepository.findByStatus(status);
    }

    // Search resources by location
    public List<BookableResource> searchByLocation(String location) {
        return resourceRepository.findByLocationContainingIgnoreCase(location);
    }

    // Search resources by name
    public List<BookableResource> searchByName(String name) {
        return resourceRepository.findByNameContainingIgnoreCase(name);
    }

    // Find resources by minimum capacity
    public List<BookableResource> findByMinimumCapacity(Integer capacity) {
        return resourceRepository.findByCapacityGreaterThanEqual(capacity);
    }
}
