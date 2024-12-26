using UnityEngine;

[RequireComponent(typeof(Animator))]
public class EnemyAnimator : MonoBehaviour
{
    private Animator animator;
    private Enemy enemy;
    
    // Animator 参数名称
    private readonly string TRIGGER_GET_HIT = "GetHit";
    private readonly string TRIGGER_GET_HEAVY_HIT = "GetHeavyHit";
    private readonly string TRIGGER_DIE = "Die";
    private readonly string TRIGGER_STUN = "Stun";
    private readonly string BOOL_IS_DEAD = "IsDead";
    private readonly string BOOL_IS_STUNNED = "IsStunned";
    
    void Start()
    {
        animator = GetComponent<Animator>();
        enemy = GetComponent<Enemy>();
        
        // 确保初始状态正确
        if (animator != null)
        {
            animator.SetBool(BOOL_IS_DEAD, false);
            animator.SetBool(BOOL_IS_STUNNED, false);
        }
    }
    
    public void PlayGetHit(bool isHeavyHit = false)
    {
        // 如果没有死亡，触发受击动画
        if (!enemy.IsDead && animator != null)
        {
            // 根据是否是重击选择播放的动画
            string triggerName = isHeavyHit ? TRIGGER_GET_HEAVY_HIT : TRIGGER_GET_HIT;
            animator.SetTrigger(triggerName);
        }
    }
    
    public void PlayDie()
    {
        if (animator != null)
        {
            animator.SetBool(BOOL_IS_DEAD, true);
            animator.SetTrigger(TRIGGER_DIE);
        }
    }
    
    public void PlayStun()
    {
        if (animator != null && !enemy.IsDead)
        {
            animator.SetBool(BOOL_IS_STUNNED, true);
            animator.SetTrigger(TRIGGER_STUN);
        }
    }
    
    public void PlayIdle()
    {
        if (animator != null && !enemy.IsDead)
        {
            animator.SetBool(BOOL_IS_STUNNED, false);
        }
    }
} 