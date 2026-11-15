package qa.udst.coworkhub.exception;

public class ConflictException extends RuntimeException{
    public ConflictException(String message) {
        super(message); // 409
    }
    
}
