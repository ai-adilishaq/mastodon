# frozen_string_literal: true

class AnnualReport::Percentiles < AnnualReport::Source
  def generate
    {
      percentiles: {
        followers: (total_with_fewer_followers / total_for_comparison.to_f) * 100,
      },
    }
  end

  private

  def followers_gained
    @followers_gained ||= @account.passive_relationships.where("date_part('year', follows.created_at) = ?", @year).count
  end

  def total_with_fewer_followers
    @total_with_fewer_followers ||= Follow.find_by_sql([<<~SQL.squish, { year: @year, comparison: followers_gained }]).first.total
      WITH tmp0 AS (
        SELECT follows.target_account_id
        FROM follows
        INNER JOIN accounts ON accounts.id = follows.target_account_id
        WHERE date_part('year', follows.created_at) = :year
          AND accounts.domain IS NULL
        GROUP BY follows.target_account_id
        HAVING COUNT(*) < :comparison
      )
      SELECT count(*) AS total
      FROM tmp0
    SQL
  end

  def total_for_comparison
    @total_for_comparison ||= Follow.where("date_part('year', follows.created_at) = ?", @year).joins(:target_account).merge(Account.local).count('distinct follows.target_account_id')
  end
end
