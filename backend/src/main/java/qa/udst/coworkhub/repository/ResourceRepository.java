
package qa.udst.coworkhub.repository;

import java.util.Optional;
import jakarta.persistence.LockModeType;
import org.springframework.data.jpa.repository.Lock;

import qa.udst.coworkhub.entity.BookableResource;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface ResourceRepository
        extends JpaRepository<BookableResource, Long> {
    @Lock(LockModeType.PESSIMISTIC_WRITE)
    @Query("select entity from BookableResource entity where entity.id = :id")
    Optional<BookableResource> findForUpdate(@org.springframework.data.repository.query.Param("id") Long id);


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

    // Find resources by minimum capacity
    List<BookableResource> findByCapacityGreaterThanEqual(
            Integer capacity
    );

    // Check whether a resource has any booking records
    @Query("SELECT CASE WHEN COUNT(b) > 0 THEN true ELSE false END " +
           "FROM Booking b WHERE b.resource.id = :resourceId")
    boolean hasBookingsForResource(
            @Param("resourceId") Long resourceId
    );
}
