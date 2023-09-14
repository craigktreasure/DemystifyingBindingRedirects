namespace Section5;

using Newtonsoft.Json;

using System;

internal static class Program
{
    private static void Main(string[] args)
    {
        Console.WriteLine("Starting.");
        string json = JsonConvert.SerializeObject(args);
        Console.WriteLine(json);
    }
}
