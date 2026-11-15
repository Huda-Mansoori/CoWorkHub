package qa.udst.coworkhub.exception;

public class BusinessRuleException extends RuntimeException{
    public BusinessRuleException(String message) {
        super(message); // 400
    }
    
}
