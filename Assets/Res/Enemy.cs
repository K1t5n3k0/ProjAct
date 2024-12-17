using UnityEngine;

public class Enemy : MonoBehaviour
{
    [Header("基础属性")]
    public float maxHealth = 100f;
    public float currentHealth;
    public float attackDamage = 10f;
    
    [Header("状态")]
    private bool isDead = false;
    private Animator animator;

    void Start()
    {
        currentHealth = maxHealth;
        animator = GetComponent<Animator>();
    }

    public void TakeDamage(float damage)
    {
        if (isDead) return;

        currentHealth -= damage;
        
        // 播放受伤动画
        animator?.SetTrigger("Hit");

        if (currentHealth <= 0)
        {
            Die();
        }
    }

    void Die()
    {
        isDead = true;
        
        // 播放死亡动画
        animator?.SetTrigger("Death");
        
        // 禁用碰撞器和其他组件
        GetComponent<Collider>().enabled = false;
        
        // 可以在这里添加死亡效果，比如经验值奖励等
    }
} 