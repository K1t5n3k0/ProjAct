using UnityEngine;

public class CharacterStats : MonoBehaviour
{
    [Header("基础属性")]
    public float maxHp = 100f;
    public float currentHp;
    public float atk = 10f;

    protected virtual void Start()
    {
        currentHp = maxHp;
    }

    public virtual void TakeDamage(float damage, bool isWeakSpotHit = false, bool isHeavyHit = false)
    {
        currentHp -= damage;
        if (currentHp <= 0)
        {
            currentHp = 0;
            Die();
        }
    }

    protected virtual void Die()
    {
        // 由子类实现具体死亡逻辑
    }
} 