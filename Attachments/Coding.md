# Coding Agreements

File is currently in todo.

## NEVER DELETE/IGNORE UNIT TEST WARNING

## Foundation

### NotificationCenter

- All notification should be post in background thread otherwise it may crash threading safe guards.
- All notification respond selector should switch to main/customized thread before execution

### DataBase

- All database should be opened and handled by each manager
- All database should be written/read by each manager

### Design

- All UI must be designed before coding
- All UI animation should use the following API

```Swift
open class func animate(withDuration duration: TimeInterval,
                        delay: TimeInterval,
                        usingSpringWithDamping dampingRatio: CGFloat,
                        initialSpringVelocity velocity: CGFloat,
                        options: UIView.AnimationOptions = [],
                        animations: @escaping () -> Void,
                        completion: ((Bool) -> Void)? = nil
                        )

```
