using UnityEngine;
using System.Collections;

public class AttackManager : MonoBehaviour
{
    [Header("攻击设置")]
    public float attackRange = 2.0f; // 普通攻击范围
    public float skillRange = 2.5f; // 技能范围

    [System.Serializable]
    public class HitConfig
    {
        public float delay = 0.2f; // 这一段攻击的延迟时间
        public float damageMultiplier = 1.0f; // 伤害倍率
        public Vector3 hitOffset = Vector3.forward; // 攻击判定的位置偏移
        public float hitRange = 2.0f; // 这一段的攻击范围
        public float lockMovementTime = 0.3f; // 这一段攻击锁定移动的时间
        public bool isHeavyHit = false; // 是否是重击
    }

    [Header("普通攻击设置")]
    public HitConfig[] attackHits; // 普通攻击段数配置

    [Header("技能设置")]
    public HitConfig[] skillHits; // 技能段数配置
    
    [Header("特效预制体")]
    public GameObject normalAttackEffect;
    public GameObject skillEffectPrefab;
    
    private CharacterStats characterStats;
    private Coroutine currentAttackCoroutine;
    private Coroutine currentSkillCoroutine;
    
    [Header("顿帧设置")]
    public float hitStopDuration = 0.2f; // 顿帧持续时间

    void Start()
    {
        characterStats = GetComponent<CharacterStats>();
        
        // 默认配置
        if (attackHits == null || attackHits.Length == 0)
        {
            attackHits = new HitConfig[] { new HitConfig() };
        }
        if (skillHits == null || skillHits.Length == 0)
        {
            skillHits = new HitConfig[] { new HitConfig() { damageMultiplier = 1.5f } };
        }
    }

    public void PerformNormalAttack()
    {
        Debug.Log("Performing normal attack sequence");
        if (currentAttackCoroutine != null)
        {
            StopCoroutine(currentAttackCoroutine);
        }
        currentAttackCoroutine = StartCoroutine(PerformHitSequence(attackHits, normalAttackEffect));
    }

    public void PerformSkill()
    {
        Debug.Log("Performing skill sequence");
        if (currentSkillCoroutine != null)
        {
            StopCoroutine(currentSkillCoroutine);
        }
        currentSkillCoroutine = StartCoroutine(PerformHitSequence(skillHits, skillEffectPrefab));
    }

    IEnumerator PerformHitSequence(HitConfig[] hits, GameObject effectPrefab)
    {
        for (int i = 0; i < hits.Length; i++)
        {
            var hitConfig = hits[i];
            
            // 等待配置的延迟时间
            yield return new WaitForSeconds(hitConfig.delay);
            
            // 执行这一段的攻击判定
            PerformSingleHit(hitConfig, effectPrefab);
            
            Debug.Log($"Performed hit {i + 1} of {hits.Length}");
        }
    }

    void PerformSingleHit(HitConfig hitConfig, GameObject effectPrefab)
    {
        // 计算攻击判定位置
        Vector3 attackPosition = transform.position + transform.rotation * hitConfig.hitOffset * hitConfig.hitRange;
        
        // 使用球形检测
        Collider[] hitColliders = Physics.OverlapSphere(
            attackPosition,
            hitConfig.hitRange,
            LayerMask.GetMask("Enemy")
        );

        bool hasHit = false; // 是否命中了任何敌人

        foreach (var hitCollider in hitColliders)
        {
            var enemy = hitCollider.GetComponent<Enemy>();
            if (enemy != null)
            {
                if (!hasHit)
                {
                    // 第一次命中时触发顿帧
                    TimeManager.Instance.DoHitStop(hitStopDuration);
                    hasHit = true;
                }

                // 检查是否击中弱点
                bool hitWeakSpot = enemy.IsWeakSpotHit(transform.position);
                
                // 应用伤害倍率
                float damage = characterStats.atk * hitConfig.damageMultiplier;
                
                // 传递重击标记
                enemy.TakeDamage(damage, hitWeakSpot, hitConfig.isHeavyHit);
                
                // 生成攻击特效
                if (effectPrefab != null)
                {
                    Instantiate(effectPrefab, hitCollider.transform.position, Quaternion.identity);
                }
            }
        }
    }

    public void EndNormalAttack()
    {
        if (currentAttackCoroutine != null)
        {
            StopCoroutine(currentAttackCoroutine);
            currentAttackCoroutine = null;
        }
    }

    public void EndSkill()
    {
        if (currentSkillCoroutine != null)
        {
            StopCoroutine(currentSkillCoroutine);
            currentSkillCoroutine = null;
        }
    }

    void OnDrawGizmosSelected()
    {
        // 显示普通攻击的所有段的范围
        if (attackHits != null)
        {
            for (int i = 0; i < attackHits.Length; i++)
            {
                var hitConfig = attackHits[i];
                Vector3 hitPosition = transform.position + transform.rotation * hitConfig.hitOffset * hitConfig.hitRange;
                
                Gizmos.color = new Color(1, 0, 0, 0.3f);
                Gizmos.DrawWireSphere(hitPosition, hitConfig.hitRange);
            }
        }
        
        // 显示技能的所有段范围
        if (skillHits != null)
        {
            for (int i = 0; i < skillHits.Length; i++)
            {
                var hitConfig = skillHits[i];
                Vector3 hitPosition = transform.position + transform.rotation * hitConfig.hitOffset * hitConfig.hitRange;
                
                Gizmos.color = new Color(0, 0, 1, 0.3f);
                Gizmos.DrawWireSphere(hitPosition, hitConfig.hitRange);
            }
        }
    }
} 