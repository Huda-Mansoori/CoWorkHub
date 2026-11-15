package qa.udst.coworkhub.exception;

public class NotFoundException extends RuntimeException{
    public NotFoundException(String message) {
        super(message); // 404
    }
}
