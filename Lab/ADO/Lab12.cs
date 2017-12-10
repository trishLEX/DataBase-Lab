using System;
using System.Data;
using System.Data.SqlClient;
using System.Configuration;
using System.Windows.Forms;

namespace ADO
{
    internal class Program
    {
        public static void Main(string[] args)
        {
            SqlConnection cn = new SqlConnection();
            cn.ConnectionString = ConfigurationManager.ConnectionStrings["SQLClient"].ConnectionString;
            cn.Open();

            string strSelect = "Select * FROM ShopSchema.Shop";
            SqlCommand cmdSelect  = new SqlCommand(strSelect, cn);

            SqlDataReader dr;
            dr = cmdSelect.ExecuteReader(CommandBehavior.CloseConnection);

            while (dr.Read())
            {
                Console.WriteLine("ShopName: {0}, isOutlet: {1}, address: {2}, city: {3}", 
                    dr["ShopName"].ToString().Trim(), dr["isOutlet"].ToString().Trim(), dr["address"].ToString().Trim(), dr["city"].ToString().Trim());
            }
            
            dr.Close();
            
            string strInsert = "INSERT INTO ShopSchema.Shop (shopName, address, city) VALUES (@shopName, @address, @city)";

            using (SqlCommand cmdInsert = new SqlCommand(strInsert, cn))
            {
                cn.Open();
                
                SqlParameter parameter = new SqlParameter();
                parameter.ParameterName = "@shopName";
                parameter.Value = "shop";
                parameter.SqlDbType = SqlDbType.NVarChar;
                cmdInsert.Parameters.Add(parameter);

                parameter = new SqlParameter();
                parameter.ParameterName = "@address";
                parameter.Value = "Baumanskaya st.";
                parameter.SqlDbType = SqlDbType.NVarChar;
                cmdInsert.Parameters.Add(parameter);
                
                parameter = new SqlParameter();
                parameter.ParameterName = "@city";
                parameter.Value = "Moscow";
                parameter.SqlDbType = SqlDbType.NVarChar;
                cmdInsert.Parameters.Add(parameter);

                int count = cmdInsert.ExecuteNonQuery();
                Console.WriteLine("\n Added rows: {0}", count);
            }

            string strUpdate = "UPDATE ShopSchema.Shop SET city = 'RIGA' WHERE shopName = 'shop'";

            using (SqlCommand cmdUpdate = new SqlCommand(strUpdate, cn))
            {
                cn.Open();

                int count = cmdUpdate.ExecuteNonQuery();
                Console.WriteLine("\n Updated rows: {0}", count);
            }

            string strDelete = "DELETE FROM ShopSchema.Shop WHERE city = 'RIGA'";

            using (SqlCommand cmdDelete = new SqlCommand(strDelete, cn))
            {
                cn.Open();
                
                int count = cmdDelete.ExecuteNonQuery();
                Console.WriteLine("\n Deleted rows: {0}", count);
            };
            
            //Несвязный уровень//
            
            //SELECT
            SqlCommand selectCmd = new SqlCommand(strSelect, cn);
            
            //INSERT
            SqlCommand insertCmd = new SqlCommand(strInsert, cn);
            SqlParameterCollection parameterCollection = insertCmd.Parameters;
            parameterCollection.Add("@shopName", SqlDbType.NVarChar, 100, "shopName");
            parameterCollection.Add("@address", SqlDbType.NVarChar, 100, "address");
            parameterCollection.Add("@city", SqlDbType.NVarChar, 50, "city");
            
            //DELETE
            SqlCommand deleteCmd = new SqlCommand(strDelete, cn);
            
            //UPDATE
            SqlCommand updateCmd = new SqlCommand(
                "UPDATE ShopSchema.Shop SET shopName = @newShopName, isOutlet = @newIsOutlet, address = @newAddress, city = @newCity" +
                " WHERE " +
                "shopCode = @oldShopCode and shopName = @oldShopName and isOutlet = @oldIsOutlet and address = @oldAddress and city = @oldCity",
                cn
                );

            parameterCollection = updateCmd.Parameters;
            parameterCollection.Add("@newShopCode", SqlDbType.Int, 4, "shopCode");
            parameterCollection.Add("@newShopName", SqlDbType.NVarChar, 100, "shopName");
            parameterCollection.Add("@newIsOutlet", SqlDbType.Bit, 1, "isOutlet");
            parameterCollection.Add("@newAddress", SqlDbType.NVarChar, 100, "address");
            parameterCollection.Add("@newCity", SqlDbType.NVarChar, 50, "city");

            SqlParameter param;
            param = parameterCollection.Add("@oldShopCode", SqlDbType.Int, 4, "shopCode");
            param.SourceVersion = DataRowVersion.Original;
            param = parameterCollection.Add("@oldShopName", SqlDbType.NVarChar, 100, "shopName");
            param.SourceVersion = DataRowVersion.Original;
            param = parameterCollection.Add("@oldIsOutlet", SqlDbType.Bit, 1, "isOutlet");
            param.SourceVersion = DataRowVersion.Original;
            param = parameterCollection.Add("@oldAddress", SqlDbType.NVarChar, 100, "address");
            param.SourceVersion = DataRowVersion.Original;
            param = parameterCollection.Add("@oldCity", SqlDbType.NVarChar, 50, "city");
            param.SourceVersion = DataRowVersion.Original;
            
            SqlDataAdapter adapter = new SqlDataAdapter();
            DataSet dataSet = new DataSet();
            adapter.SelectCommand = selectCmd;
            adapter.InsertCommand = insertCmd;
            adapter.UpdateCommand = updateCmd;
            adapter.DeleteCommand = deleteCmd;


            adapter.Fill(dataSet, "Shop");
            
            DataRow newRow = dataSet.Tables["Shop"].NewRow();
            newRow["shopName"] = "shop";
            newRow["address"] = "Baumanskaya st.";
            newRow["city"] = "Moscow";
            dataSet.Tables["Shop"].Rows.Add(newRow);

            int n = dataSet.Tables["Shop"].Rows.Count;
            for (int i = 0; i < n; i++)
            {
                DataRow row = dataSet.Tables["Shop"].Rows[i];
                if (String.Compare(row["shopName"].ToString(), "shop") == 0)
                {
                    row["city"] = "RIGA";
                }
            }
            
            int k = dataSet.Tables["Shop"].Rows.Count;
            for (int i = 0; i < k; i++)
            {
                DataRow row = dataSet.Tables["Shop"].Rows[i];
                if (String.Compare(row["shopName"].ToString(), "shop") == 0)
                {
                    row.Delete();
                }
            }

            adapter.Update(dataSet, "Shop");
            
            cn.Close();
        }
    }
}
