package qa.udst.coworkhub;

import jakarta.validation.Validation;
import org.junit.jupiter.api.Test;
import org.springframework.web.server.ResponseStatusException;
import qa.udst.coworkhub.controller.BookingRequest;
import qa.udst.coworkhub.entity.Member;
import qa.udst.coworkhub.repository.BookingRepository;
import qa.udst.coworkhub.repository.MemberRepository;
import qa.udst.coworkhub.repository.ResourceRepository;
import qa.udst.coworkhub.service.BookingService;
import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.Mockito.*;

class BookingValidationTests {
    @Test
    void missingMemberAndResourceReturnBadRequest() {
        var service = new BookingService(mock(BookingRepository.class),
                mock(MemberRepository.class), mock(ResourceRepository.class));
        var error = assertThrows(ResponseStatusException.class,
                () -> service.createBooking(new BookingRequest()));
        assertEquals(400, error.getStatusCode().value());
    }

    @Test
    void blankMemberAndInvalidEmailFailValidation() {
        try (var factory = Validation.buildDefaultValidatorFactory()) {
            var violations = factory.getValidator().validate(new Member("", "invalid"));
            assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("fullName")));
            assertTrue(violations.stream().anyMatch(v -> v.getPropertyPath().toString().equals("email")));
        }
    }
}
