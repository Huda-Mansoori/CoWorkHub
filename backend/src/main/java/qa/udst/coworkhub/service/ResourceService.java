
package qa.udst.coworkhub.service;

import qa.udst.coworkhub.entity.BookableResource;
import qa.udst.coworkhub.entity.Desk;
import qa.udst.coworkhub.entity.MeetingRoom;
import qa.udst.coworkhub.entity.ResourceStatus;
import qa.udst.coworkhub.repository.ResourceRepository;

import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

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
                .orElseThrow(() -> new ResponseStatusException(
                        HttpStatus.NOT_FOUND,
                        "Resource not found with ID: " + id
                ));
    }

    // Create a new resource
    public BookableResource createResource(BookableResource resource) {
        return resourceRepository.save(resource);
    }

    
    // Update an existing resource, including subtype-specific fields
    public BookableResource updateResource(
            Long id, BookableResource updatedResource) {

        BookableResource existingResource = getResourceById(id);

        // Prevent changing the resource type
        if (existingResource.getClass() != updatedResource.getClass()) {
            throw new ResponseStatusException(
                    HttpStatus.BAD_REQUEST,
                    "Resource type mismatch. You must update a resource using its correct type."
            );
        }

        // Update common fields
        existingResource.setName(updatedResource.getName());
        existingResource.setLocation(updatedResource.getLocation());
        existingResource.setCapacity(updatedResource.getCapacity());
        existingResource.setHourlyRate(updatedResource.getHourlyRate());
        existingResource.setStatus(updatedResource.getStatus());

        // Update meeting room-specific fields
        if (existingResource instanceof MeetingRoom) {

            MeetingRoom existingRoom = (MeetingRoom) existingResource;
            MeetingRoom updatedRoom = (MeetingRoom) updatedResource;

            existingRoom.setProjector(updatedRoom.getProjector());
            existingRoom.setVideoConference(
                    updatedRoom.getVideoConference()
            );
        }

        // Update desk-specific fields
        if (existingResource instanceof Desk) {

            Desk existingDesk = (Desk) existingResource;
            Desk updatedDesk = (Desk) updatedResource;

            existingDesk.setDeskType(updatedDesk.getDeskType());
        }

        return resourceRepository.save(existingResource);
    }


    // Delete resource only if it has no booking records
    public void deleteResource(Long id) {

        BookableResource resource = getResourceById(id);

        if (resourceRepository.hasBookingsForResource(id)) {
            throw new ResponseStatusException(
                    HttpStatus.CONFLICT,
                    "Cannot delete this resource because it has booking records. "
                    + "Set its status to OUT_OF_SERVICE instead."
            );
        }

        resourceRepository.delete(resource);
    }

    // Filter resources by status
    public List<BookableResource> getResourcesByStatus(
            ResourceStatus status) {
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
