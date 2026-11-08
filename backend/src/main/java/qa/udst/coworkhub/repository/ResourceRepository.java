
package qa.udst.coworkhub.repository;

import qa.udst.coworkhub.entity.BookableResource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ResourceRepository
        extends JpaRepository<BookableResource, Long> {

    // Find resources by status
    List<BookableResource> findByStatus(
            qa.udst.coworkhub.entity.ResourceStatus status
    );

    // Find resources by location
    List<BookableResource> findByLocationContainingIgnoreCase(
            String location
    );

    // Find resources by name
    List<BookableResource> findByNameContainingIgnoreCase(
            String name
    );

    // Find resources by capacity
    List<BookableResource> findByCapacityGreaterThanEqual(
            Integer capacity
    );
}
